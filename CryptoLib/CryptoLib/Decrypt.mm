//
//  Decrypt.mm
//  CryptoLib
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#import "Decrypt.h"
#import "Extensions.h"
#import "SmartCardTokenWrapper.h"
#import <CryptoLib/CryptoLib-Swift.h>

#include <cdoc/CdocReader.h>
#include <cdoc/Configuration.h>
#include <cdoc/Lock.h>
#include <cdoc/NetworkBackend.h>
#include <cdoc/Recipient.h>

@implementation Addressee (label)

- (instancetype)initWithLabel:(const std::string &)label pub:(NSData*)pub {
    std::map<std::string, std::string> info = libcdoc::Recipient::parseLabel(label);
    id cn = info.contains("cn") ? [NSString stringWithStdString:info["cn"]] : nil;
    id type = info.contains("last_name") ? [NSString stringWithStdString:info["type"]] : nil;
    CertType certType = CertTypeUnknownType;
    if ([type isEqualToString:@"ID-card"]) {
        certType = CertTypeIDCardType;
    } else if ([type isEqualToString:@"Digi-ID"]) {
        certType = CertTypeDigiIDType;
    } else if ([type isEqualToString:@"Digi-ID E-RESIDENT"]) {
        certType = CertTypeEResidentType;
    }
    id validTo = nil;
    if (info.contains("server_exp")) {
        long long epochTime = [[NSString stringWithStdString:info["server_exp"]] longLongValue];
        validTo = [NSDate dateWithTimeIntervalSince1970:epochTime];
    }
    if (self = [self initWithCn:cn certType:certType validTo:validTo data:pub]) {
    }
    return self;
}

@end

struct Settings: public libcdoc::Configuration {
    std::string getValue(std::string_view domain, std::string_view param) const final {
        if(param == KEYSERVER_FETCH_URL)
            return [CDoc2Settings.getFetchURL toString];
        if(param == KEYSERVER_SEND_URL)
            return [CDoc2Settings.getPostURL toString];
        return {};
    }
};

struct Network: public libcdoc::NetworkBackend
{
    std::vector<uint8_t> cert;
    SmartCardTokenWrapper *token = nullptr;

    libcdoc::result_t getClientTLSCertificate(std::vector<uint8_t> &dst) final {
        dst = cert;
        return libcdoc::OK;
    }

    libcdoc::result_t signTLS(std::vector<uint8_t> &dst, libcdoc::CryptoBackend::HashAlgorithm algorithm, const std::vector<uint8_t> &digest) final {
        return token->sign(dst, algorithm, digest, 0);
    }
};

@implementation Decrypt

+ (void)parseCdocInfoWithFullPath:(NSString *)fullPath success:(void (^)(CdocInfo *))success {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if([fullPath.pathExtension caseInsensitiveCompare:@"cdoc"] == NSOrderedSame) {
            CdocInfo *result = [CdocParser parseWithPath:fullPath];
            return dispatch_async(dispatch_get_main_queue(), ^{ success(result); });
        }

        std::unique_ptr<libcdoc::CDocReader> reader(libcdoc::CDocReader::createReader(fullPath.UTF8String, nullptr, nullptr, nullptr));
        if(!reader)
            return dispatch_async(dispatch_get_main_queue(), ^{ success(nil); });
        NSMutableArray<Addressee*> *addressees = [[NSMutableArray alloc] init];
        for(const libcdoc::Lock &lock: reader->getLocks())
        {
            if(lock.isCertificate()) {
                [addressees addObject:[[Addressee alloc] initWithLabel:lock.label pub:[NSData dataFromVector:lock.getBytes(libcdoc::Lock::CERT)]]];
            } else if(lock.isPKI()) {
                [addressees addObject:[[Addressee alloc] initWithLabel:lock.label pub:[NSData dataFromVector:lock.getBytes(libcdoc::Lock::RCPT_KEY)]]];
            } else {
                [addressees addObject:[[Addressee alloc] initWithCn:@"Unknown capsule" pub:[NSData data]]];
            }
        }

        CdocInfo *result = [[CdocInfo alloc] initWithAddressees:addressees];
        return dispatch_async(dispatch_get_main_queue(), ^{ success(result); });
    });
}

+ (NSDictionary<NSString*,NSData*> *)decryptFile:(NSString *)fullPath withPin:(NSString *)pin withToken:(id<AbstractSmartToken>)smartToken error:(NSError**)error {
    SmartCardTokenWrapper token(pin.UTF8String, smartToken);
    Settings conf;
    Network network;
    network.token = &token;
    network.cert = token.cert();
    if(network.cert.empty()) {
        if (error != nil) {
            *error = token.lastError();
        }
        return nil;
    }

    std::unique_ptr<libcdoc::CDocReader> reader(libcdoc::CDocReader::createReader(fullPath.UTF8String, &conf, &token, &network));

    auto idx = reader->getLockForCert(network.cert);
    if(idx < 0)
        return nil;
    std::vector<uint8_t> fmk;
    if(reader->getFMK(fmk, unsigned(idx)) != 0 || fmk.empty()) {
        if (error != nil) {
            *error = token.lastError();
        }
        return nil;
    }
    if(reader->beginDecryption(fmk) != 0)
        return nil;

    NSMutableDictionary<NSString*,NSData*> *response = [NSMutableDictionary new];
    std::string name;
    int64_t size{};
    while((reader->nextFile(name, size)) == 0)
    {
        NSMutableData *data = [[NSMutableData alloc] initWithLength:16 * 1024];
        NSUInteger currentLength = 0;

        uint64_t bytesRead = 0;
        while (true) {
            bytesRead = reader->readData(reinterpret_cast<uint8_t *>(data.mutableBytes) + currentLength, 16 * 1024);
            if (bytesRead < 0) {
                NSLog(@"Error reading data from file: %s", name.c_str());
                break;
            }

            currentLength += bytesRead;
            [data setLength:currentLength];
            if (bytesRead == 0) {
                break;
            }
            [data increaseLengthBy:16 * 1024];
        }
        [response setObject:data forKey:[NSString stringWithStdString:name]];
    }
    if (reader->finishDecryption() != 0)
        return nil;
    return response;
}

@end

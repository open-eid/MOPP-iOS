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
#include <cdoc/Lock.h>
#include <cdoc/Recipient.h>

@implementation Decrypt

+ (CdocInfo*)cdocInfo:(NSString *)fullPath error:(NSError**)error {
    return [[CdocInfo alloc] initWithCdoc1Path:fullPath error:error];
}

+ (void)decryptFile:(NSString *)fullPath withToken:(id<AbstractSmartToken>)smartToken
         completion:(void (^)(NSDictionary<NSString*,NSData*> *, NSError *))completion {
    [smartToken getCertificateWithCompletionHandler:^(NSData *certData, NSError *error) {
        auto cert = [certData toVector];
        if(cert.empty()) {
            return completion(nil, error);
        }

        SmartCardTokenWrapper token(smartToken);
        std::unique_ptr<libcdoc::CDocReader> reader(libcdoc::CDocReader::createReader(fullPath.UTF8String, nullptr, &token, nullptr));

        auto idx = reader->getLockForCert(cert);
        if(idx < 0) {
            return completion(nil, [NSError cryptoError:@"Failed to find lock for cert"]);
        }
        std::vector<uint8_t> fmk;
        if(reader->getFMK(fmk, unsigned(idx)) != 0 || fmk.empty()) {
            return completion(nil, token.lastError() ?: [NSError cryptoError:@"Failed to get FMK"]);
        }
        if(reader->beginDecryption(fmk) != 0) {
            return completion(nil, [NSError cryptoError:@"Failed to start encryption"]);
        }

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
                    return completion(nil, [NSError cryptoError:@"Failed to decrypt file"]);
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
            return completion(nil, [NSError cryptoError:@"Failed to end encryption"]);
        return completion(response, nil);
    }];
}

@end

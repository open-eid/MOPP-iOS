//
//  Encrypt.mm
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

#import "Encrypt.h"
#import "Extensions.h"

#import <CryptoLib/CryptoLib-Swift.h>

#include <cdoc/CDocWriter.h>
#include <cdoc/Configuration.h>
#include <cdoc/NetworkBackend.h>
#include <cdoc/Recipient.h>

struct Settings: public libcdoc::Configuration {
    std::string getValue(std::string_view domain, std::string_view param) const final {
        if(param == KEYSERVER_FETCH_URL)
            return [CDoc2Settings.getFetchURL toString];
        if(param == KEYSERVER_SEND_URL)
            return [CDoc2Settings.getPostURL toString];
        return {};
    }
};

@implementation Encrypt

+ (void)encryptFile:(NSString *)fullPath withDataFiles:(NSArray<CryptoDataFile*> *)dataFiles withAddressees:(NSArray<Addressee*> *)addressees
            success:(void (^)(void))success failure:(void (^)(void))failure {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int version = [fullPath.pathExtension caseInsensitiveCompare:@"cdoc2"] == NSOrderedSame ? 2 : 1;
        Settings conf;
        libcdoc::NetworkBackend network;
        std::unique_ptr<libcdoc::CDocWriter> writer(libcdoc::CDocWriter::createWriter(version, fullPath.UTF8String, &conf, nullptr, &network));

        if (!writer) {
            return dispatch_async(dispatch_get_main_queue(), failure);
        }

        if (version == 2 && CDoc2Settings.isOnlineEncryptionEnabled) {
            NSString *server_id = CDoc2Settings.getSelectedService;
            for (Addressee *addressee in addressees) {
                if (writer->addRecipient(libcdoc::Recipient::makeEIDServer([addressee.data toVector], [server_id toString])) != 0) {
                    return dispatch_async(dispatch_get_main_queue(), failure);
                }
            }
        } else {
            for (Addressee *addressee in addressees) {
                if (writer->addRecipient(libcdoc::Recipient::makeEID([addressee.data toVector])) != 0) {
                    return dispatch_async(dispatch_get_main_queue(), failure);
                }
            }
        }

        if (writer->beginEncryption() != 0) {
            return dispatch_async(dispatch_get_main_queue(), failure);
        }

        for (CryptoDataFile *dataFile in dataFiles) {
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:dataFile.filePath];
            if (!fileHandle) {
                NSLog(@"Failed to open file at path: %@", dataFile.filePath);
                return dispatch_async(dispatch_get_main_queue(), failure);
            }

            if (writer->addFile(dataFile.filename.UTF8String, [fileHandle seekToEndOfFile]) != 0) {
                return dispatch_async(dispatch_get_main_queue(), failure);
            }
            [fileHandle seekToFileOffset:0];

            NSUInteger blockSize = 1024 * 16;
            NSData *data;
            while ((data = [fileHandle readDataOfLength:blockSize]) && data.length > 0) {
                if (writer->writeData(reinterpret_cast<const uint8_t*>(data.bytes), data.length) != 0) {
                    return dispatch_async(dispatch_get_main_queue(), failure);
                }
            }
            [fileHandle closeFile];
        }
        bool result = writer->finishEncryption() == 0;
        dispatch_async(dispatch_get_main_queue(), result ? success : failure);
    });
}

@end

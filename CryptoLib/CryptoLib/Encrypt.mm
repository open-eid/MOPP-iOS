//
//  Encrypt.mm
//  CryptoLib
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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
#import "Addressee.h"
#import "CryptoDataFile.h"
#import "cdoc/CdocWriter.h"


@implementation Encrypt

- (void)encryptFile: (NSString *)fullPath withDataFiles :(NSArray *) dataFiles withAddressees: (NSArray *) addressees {
    
    std::string encodedFullPath = std::string([fullPath UTF8String]);
    
    CDOCWriter cdocWriter(encodedFullPath, "http://www.w3.org/2009/xmlenc11#aes256-gcm");
    
    for (CryptoDataFile *dataFile in dataFiles) {
        std::string encodedDataFilePath = std::string([dataFile.filePath UTF8String]);
        std::string encodedFilename = std::string([dataFile.filename UTF8String]);
        cdocWriter.addFile(encodedFilename, "application/octet-stream", encodedDataFilePath);
    }
    for (Addressee *addressee in addressees) {
        NSData *cert = addressee.cert;
        unsigned char *buffer = reinterpret_cast<unsigned char*>(const_cast<void*>(cert.bytes));
        std::vector<unsigned char> result = std::vector<unsigned char>(buffer, buffer + cert.length);
        
        cdocWriter.addRecipient(result);
    }
    
    cdocWriter.encrypt();

}

@end

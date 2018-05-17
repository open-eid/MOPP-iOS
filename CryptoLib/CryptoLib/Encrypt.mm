//
//  Encrypt.mm
//  CryptoLib
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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
#import "cdoc/CdocWriter.h"


@implementation Encrypt

- (void)encryptFile : (NSString *)fullPath withPath: (NSString *) dataFilePath withCert: (NSData *) cert withName: (NSString *) filename {
    
    std::string encodedFullPath = std::string([fullPath UTF8String]);
    std::string encodedDataFilePath = std::string([dataFilePath UTF8String]);
    std::string encodedFilename = std::string([filename UTF8String]);
    
    const void *bytes = [cert bytes];
    NSMutableArray *ary = [NSMutableArray array];
    for (NSUInteger i = 0; i < [cert length]; i += sizeof(int8_t)) {
        int8_t elem = OSReadLittleInt(bytes, i);
        [ary addObject:[NSNumber numberWithInt:elem]];
    }
    
    std::vector<unsigned char> result;
    result.reserve(ary.count);
    for (NSNumber* bar in ary) {
        result.push_back(bar.charValue);
    }
    
    CDOCWriter cdocWriter(encodedFullPath, "http://www.w3.org/2009/xmlenc11#aes256-gcm");
    
    cdocWriter.addFile(encodedFilename, "application/octet-stream", encodedDataFilePath);
    cdocWriter.addRecipient(result);
    cdocWriter.encrypt();

}

@end

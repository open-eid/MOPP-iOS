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
#import "SmartCardTokenWrapper.h"
#import "DdocParserDelegate.h"

#import <cdoc/CdocReader.h>
#import <cdoc/Token.h>

@implementation Decrypt

+ (NSDictionary<NSString*,NSData*> *)decryptFile:(NSString *)fullPath withToken:(id<AbstractSmartToken>)smartToken error:(NSError**)error {

    std::string encodedFullPath = std::string([fullPath UTF8String]);
    CDOCReader cdocReader(encodedFullPath);
    SmartCardTokenWrapper token(smartToken);

    std::vector<unsigned char> decryptedData = cdocReader.decryptData(&token);
    *error = token.lastError();
    if (*error != nil){
        return nil;
    }
    NSData *decrypted = [NSData dataWithBytes:decryptedData.data() length:decryptedData.size()];
    std::string filename = cdocReader.fileName();
    std::string mimetype = cdocReader.mimeType();

    NSMutableDictionary<NSString*,NSData*> *response = [NSMutableDictionary new];
    NSString *nsFilename = [NSString stringWithCString:filename.c_str() encoding: NSUTF8StringEncoding];
    if ([[nsFilename pathExtension] isEqualToString: @"ddoc"]){
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:decrypted];
        DdocParserDelegate *parserDelegate = [[DdocParserDelegate alloc] init];
        [parser setDelegate:(id)parserDelegate];
        [parser parse];
        NSMutableDictionary *fileDictionary;
        fileDictionary = parserDelegate.dictionary;
        for (id key in fileDictionary){
            NSString *value = [fileDictionary objectForKey:key];
            NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString: value options:NSDataBase64DecodingIgnoreUnknownCharacters];
            [response setObject:nsdataFromBase64String forKey:key];
            
        }
    } else {
        [response setObject:decrypted forKey:nsFilename];
    }
    return response;
}

@end

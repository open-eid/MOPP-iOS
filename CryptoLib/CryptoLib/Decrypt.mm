//
//  Decrypt.mm
//  CryptoLib
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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
#import "cdoc/CdocReader.h"
#import "cdoc/Token.h"
#import "SmartCardTokenWrapper.h"
#import "DdocParserDelegate.h"
#import "base64.h"
#import <UIKit/UIKit.h>

@implementation Decrypt

- (NSMutableDictionary *)decryptFile: (NSString *)fullPath withPin :(NSString *) pin withToken :(AbstractSmartToken *) smartToken {
    
    std::string encodedFullPath = std::string([fullPath UTF8String]);
    std::string encodedPin = std::string([pin UTF8String]);
    CDOCReader cdocReader(encodedFullPath);
    std::unique_ptr<SmartCardTokenWrapper> smartCardWrapper = std::make_unique<SmartCardTokenWrapper>(encodedPin, smartToken);

    Token *token;
    token = smartCardWrapper.get();
    NSMutableDictionary *response = [NSMutableDictionary new];
    std::vector<unsigned char> decryptedData = cdocReader.decryptData(token);
    if (decryptedData.empty()){
        return response;
    }
    std::string encoded = base64_encode(reinterpret_cast<const unsigned char*>(&decryptedData[0]), (uint32_t)decryptedData.size());
    std::string filename = cdocReader.fileName();
    std::string mimetype = cdocReader.mimeType();
    NSString* result = [NSString stringWithUTF8String:encoded.c_str()];
    
    NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:result options:0];

    NSString *nsFilename = [NSString stringWithCString:filename.c_str() encoding: NSUTF8StringEncoding];
    if ([[nsFilename pathExtension] isEqualToString: @"ddoc"]){
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:nsdataFromBase64String];
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
        [response setObject:nsdataFromBase64String forKey:nsFilename];
    }
    return response;
}

@end

//
//  Decrypt.mm
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

#import "Decrypt.h"
#import "cdoc/CdocReader.h"
#import "cdoc/Token.h"
#import "ApduToken.h"
#import "XmlParserDelegate.h"
#import "base64.h"
#import <UIKit/UIKit.h>

@implementation Decrypt

- (BOOL)decryptFile: (NSString *)fullPath withPin :(NSString *) pin withToken :(ApduToken *) apduToken {
    
    std::string encodedFullPath = std::string([fullPath UTF8String]);
    std::string encodedPin = std::string([pin UTF8String]);
    CDOCReader cdocReader(encodedFullPath);
    
    Token *token;
    token = apduToken;

    std::vector<unsigned char> response = cdocReader.decryptData(token);
    if (response.empty()){
        return NO;
    }
    std::string encoded = base64_encode(reinterpret_cast<const unsigned char*>(&response[0]), (uint32_t)response.size());
    std::string filename = cdocReader.fileName();
    std::string mimetype = cdocReader.mimeType();
    NSString* result = [NSString stringWithUTF8String:encoded.c_str()];
    
    NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:result options:0];
    NSError *error = nil;
    NSArray *myArray = [fullPath componentsSeparatedByString:@"/"];

    NSString *nsFilename = [NSString stringWithCString:filename.c_str() encoding:[NSString defaultCStringEncoding]];
    if ([[nsFilename pathExtension] isEqualToString: @"ddoc"]){
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:nsdataFromBase64String];
        XmlParserDelegate *parserDelegate = [[XmlParserDelegate alloc] init];
        [parser setDelegate:(id<NSXMLParserDelegate>)parserDelegate];
        [parser parse];
        NSMutableDictionary *fileDictionary;
        fileDictionary = parserDelegate.dictionary;
        for (id key in fileDictionary){
            NSString *tempFullPath = [fullPath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"/%@", myArray[[myArray count]-1]] withString:[NSString stringWithFormat:@"/temp/%@", key]];
            NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:[fileDictionary objectForKey:key] options:0];

            BOOL success = [nsdataFromBase64String writeToFile:tempFullPath options:NSDataWritingAtomic error:&error];
            if (success){
                NSLog(@"File creation succeed with path: %@ ", tempFullPath);
            } else {
                NSLog(@"File creation failed with path: %@ ", tempFullPath);
            }
            
        }
    } else {
        fullPath = [fullPath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"/%@", myArray[[myArray count]-1]] withString:[NSString stringWithFormat:@"/temp/%@", nsFilename]];
        BOOL success = [nsdataFromBase64String writeToFile:fullPath options:NSDataWritingAtomic error:&error];
        if (success){
            NSLog(@"File creation succeed with path: %@ ", fullPath);
        } else {
            NSLog(@"File creation failed with path: %@ ", fullPath);
        }
    }
    return YES;
}

@end

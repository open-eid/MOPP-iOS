//
//  NSObject+CdocReaderWrapper.m
//  CryptoLib
//
//  Created by Siim Suu on 03/04/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

#import "CdocReaderWrapper.h"
#import "cdoc/CdocReader.h"
#import "cdoc/Token.h"
#import "ApduToken.h"
#import "XmlParserDelegate.h"
#import "base64.h"
#import <UIKit/UIKit.h>

@implementation CdocReaderWrapper

- (BOOL)decryptFile: (NSString *)fullPath withPin :(NSString *) pin withController :(UIViewController *) controller {
    
    std::string encodedFullPath = std::string([fullPath UTF8String]);
    std::string encodedPin = std::string([pin UTF8String]);
    CDOCReader cdocReader(encodedFullPath);
    
    ApduToken apduToken(encodedPin, controller);
    
    Token *s;
    s = &apduToken;

    std::vector<unsigned char> response = cdocReader.decryptData(s);
    if(response.empty()){
        return NO;
    }
    std::string encoded = base64_encode(reinterpret_cast<const unsigned char*>(&response[0]), response.size());
    std::string filename = cdocReader.fileName();
    std::string mimetype = cdocReader.mimeType();
    NSString* result2 = [NSString stringWithUTF8String:encoded.c_str()];
    
    NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:result2 options:0];
    NSError *error = nil;
    NSArray *myArray = [fullPath componentsSeparatedByString:@"/"];

    NSString *nsFilename = [NSString stringWithCString:filename.c_str() encoding:[NSString defaultCStringEncoding]];
    if([[nsFilename pathExtension] isEqualToString: @"ddoc"]){
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:nsdataFromBase64String];
        XmlParserDelegate *parserDelegate = [[XmlParserDelegate alloc] init];
        [parser setDelegate:parserDelegate];
        [parser parse];
        NSMutableDictionary *fileDictionary;
        fileDictionary = parserDelegate.dictionary;
        for(id key in fileDictionary){
            NSString *tempFullPath = [fullPath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"/%@", myArray[[myArray count]-1]] withString:[NSString stringWithFormat:@"/temp/%@", key]];
            NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:[fileDictionary objectForKey:key] options:0];

            BOOL success = [nsdataFromBase64String writeToFile:tempFullPath options:NSDataWritingAtomic error:&error];
            if(success){
                NSLog(@"File creation succeed with path: %@ ", tempFullPath);
            }else{
                NSLog(@"File creation failed with path: %@ ", tempFullPath);
            }
            
        }
    }else{
        fullPath = [fullPath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"/%@", myArray[[myArray count]-1]] withString:[NSString stringWithFormat:@"/temp/%@", nsFilename]];
        BOOL success = [nsdataFromBase64String writeToFile:fullPath options:NSDataWritingAtomic error:&error];
        if(success){
            NSLog(@"File creation succeed with path: %@ ", fullPath);
        }else{
            NSLog(@"File creation failed with path: %@ ", fullPath);
        }
    }
    return YES;
}

@end

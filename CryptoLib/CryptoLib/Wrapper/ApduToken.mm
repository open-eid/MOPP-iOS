//
//  ApduToken.cpp
//  CryptoLib
//
//  Created by Siim Suu on 04/04/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

#include "ApduToken.h"

#import "cdoc/Token.h"
#import <UIKit/UIKit.h>
#include <iostream>
#include "base64.h"

class ApduToken::Private{
public:
    
    std::vector<uchar> certResponse;
    std::vector<uchar> decryptResponse;
};
    UIViewController *uiViewController;

std::vector<uchar>  cert;
std::string pin1;
ApduToken::ApduToken(const std::string &password, UIViewController *controller)
: d(new Private){
    uiViewController = controller;
    pin1 = password;
}

std::vector<uchar> ApduToken::cert() const{
    
//    [[CardActionsManager sharedInstance] authenticationCertDataWithViewController:uiViewController success:^(NSData *certDataBlock){
//
//        const void *bytes = [certDataBlock bytes];
//        NSMutableArray *ary = [NSMutableArray array];
//        for (NSUInteger i = 0; i < [certDataBlock length]; i += sizeof(int8_t)) {
//            int8_t elem = OSReadLittleInt(bytes, i);
//            [ary addObject:[NSNumber numberWithInt:elem]];
//        }
//        std::vector<uchar> result;
//
//        result.reserve(ary.count);
//        for (NSNumber* bar in ary) {
//            result.push_back(bar.charValue);
//        }
//        d->certResponse = result;
//    } failure:^(NSError *error) {
//    }];
    printf("CERT ON TEHTUD::\n");

    return d->certResponse;
}

std::vector<uchar> ApduToken::decrypt(const std::vector<uchar> &data) const{
    std::vector<uchar> result;
    printf("DECRYTIB:\n");
    std::string encoded = base64_encode(reinterpret_cast<const unsigned char*>(&data[0]), data.size());
    NSString* result2 = [NSString stringWithUTF8String:encoded.c_str()];
    
    NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:result2 options:0];
    NSString* pin1Encoded = [NSString stringWithUTF8String:pin1.c_str()];
 
//    [[CardActionsManager sharedInstance] dataDecryption:nsdataFromBase64String pin1:pin1Encoded controller:uiViewController useECC:false success:^(NSData *certDataBlock){
//
//        const void *bytes = [certDataBlock bytes];
//        NSMutableArray *ary = [NSMutableArray array];
//        for (NSUInteger i = 0; i < [certDataBlock length]; i += sizeof(int8_t)) {
//            int8_t elem = OSReadLittleInt(bytes, i);
//            [ary addObject:[NSNumber numberWithInt:elem]];
//        }
//        std::vector<uchar> result;
//
//        result.reserve(ary.count);
//        for (NSNumber* bar in ary) {
//                result.push_back(bar.charValue);
//        }
//        //NSLog(@"%@", certResponse);
//        d->decryptResponse = result;
//
//
//    } failure:^(NSError *error) {
//        printf("PEKKI LAKS MIDAGI");
//    }];
    return d->decryptResponse;
}

std::vector<uchar> ApduToken::derive(const std::vector<uchar> &publicKey) const{
    std::vector<uchar> result;
    printf("DERIVIB HAKKAB::");
    std::string encoded = base64_encode(reinterpret_cast<const unsigned char*>(&publicKey[0]), publicKey.size());
    NSString* result2 = [NSString stringWithUTF8String:encoded.c_str()];
    
    NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:result2 options:0];
    NSString* pin1Encoded = [NSString stringWithUTF8String:pin1.c_str()];
//    [[CardActionsManager sharedInstance] dataDecryption:nsdataFromBase64String pin1:pin1Encoded controller:uiViewController useECC:true success:^(NSData *certDataBlock){
//        const void *bytes = [certDataBlock bytes];
//        NSMutableArray *ary = [NSMutableArray array];
//        for (NSUInteger i = 0; i < [certDataBlock length]; i += sizeof(int8_t)) {
//            int8_t elem = OSReadLittleInt(bytes, i);
//            [ary addObject:[NSNumber numberWithInt:elem]];
//        }
//        std::vector<uchar> result;
//
//        result.reserve(ary.count);
//        for (NSNumber* bar in ary) {
//            result.push_back(bar.charValue);
//        }
//        //NSLog(@"%@", certResponse);
//        d->decryptResponse = result;
//
//
//    } failure:^(NSError *error) {
//        printf("PEKKI LAKS MIDAGI");
//    }];
    return d->decryptResponse;
}

ApduToken::ApduToken()
{
    
}

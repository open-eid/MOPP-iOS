//
//  MoppLibCryptoActions.m
//  MoppLib
//
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

#import "MoppLibCryptoActions.h"
#import "MoppLibError.h"
#import "CryptoLib/Addressee.h"
#import "CryptoLib/CryptoDataFile.h"
#import "CryptoLib/Encrypt.h"
#import "CryptoLib/Decrypt.h"
#import "CryptoLib/CdocParser.h"
#import <CryptoLib/CryptoLib-Swift.h>
#import "CryptoLib/CdocInfo.h"
#import "SmartToken.h"
#include <stdio.h>
#import "NSData+Additions.h"
#include "MoppLibDigidocMAnager.h"
#import "MoppLibManager.h"

@implementation MoppLibCryptoActions

+ (MoppLibCryptoActions *)sharedInstance {
    static dispatch_once_t pred;
    static MoppLibCryptoActions *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)parseCdocInfo:(NSString *)fullPath success:(CdocContainerBlock)success failure:(FailureBlock)failure {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        CdocInfo *response;
        @try {
            CdocParser *cdocParser = [CdocParser new];
            response = [cdocParser parseCdocInfo:fullPath];
            if (response.addressees == nil || response.dataFiles == nil) {
                error = [MoppLibError generalError];
            }
        }
        @catch (...) {
            error = [MoppLibError generalError];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            error == nil ? success(response) : failure(error);
        });
    });
}

- (void)decryptData:(NSString *)fullPath withPin1:(NSString*)pin1 success:(DecryptedDataBlock)success failure:(FailureBlock)failure {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        NSMutableDictionary *response;
        @try {
            Decrypt *decrypter = [Decrypt new];
            SmartToken *smartToken = [SmartToken new];
            response = [decrypter decryptFile:fullPath withPin:pin1 withToken:smartToken];
            if (response.count==0) {
                error = [MoppLibError generalError];
            }
        }
        @catch (NSException *exception) {
            if([[exception name] hasPrefix:@"wrong_pin"]) {
                // Last character of wrong_pin shows retry count
                NSString *retryCount = [[exception name] substringFromIndex: [[exception name] length] - 1];
                if ([retryCount intValue] < 1) {
                    error = [MoppLibError pinBlockedError];
                } else {
                    error = [MoppLibError wrongPinErrorWithRetryCount:[retryCount intValue]];
                }
            } else if ([[exception name] isEqualToString:@"pin_blocked"]) {
                error = [MoppLibError pinBlockedError];
            } else {
                error = [MoppLibError generalError];
            }
        }
        @catch (...) {
            error = [MoppLibError generalError];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            error == nil ? success(response) : failure(error);
        });
    });
}

- (void)encryptData:(NSString *)fullPath withDataFiles:(NSArray*)dataFiles withAddressees:(NSArray*)addressees success:(VoidBlock)success failure:(FailureBlock)failure {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        @try {
            Encrypt *encrypter = [[Encrypt alloc] init];
            [encrypter encryptFile:fullPath withDataFiles:dataFiles withAddressees:addressees];
        }
        @catch (...) {
            error = [MoppLibError generalError];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            error == nil ? success() : failure(error);
        });
    });
}

@end

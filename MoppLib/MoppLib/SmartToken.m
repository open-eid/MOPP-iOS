//
//  SmartToken.m
//  CryptoLib
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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

#import <Foundation/Foundation.h>
#import "SmartToken.h"
#import "CardActionsManager.h"
#import "MoppLibError.h"

@interface SmartToken()

- (NSString*)handleErrorMessage:(NSError*)error;

@end

@implementation SmartToken

- (NSData*)getCertificate {
    __block NSData *response = nil;
    [[CardActionsManager sharedInstance] authenticationCertDataWithSuccess:^(NSData *certDataBlock) {
        const void *bytes = [certDataBlock bytes];
        NSUInteger endByteOfCertificate = [certDataBlock length];
        
        // Trim nulls from the end of certificate data
        BOOL certLengthReduced = NO;
        for (NSUInteger i = [certDataBlock length]; i > 0;) {
            int8_t elem = OSReadLittleInt(bytes, i - 1);
            if(elem != '\0'){
                endByteOfCertificate = i;
                break;
            }
            i -= sizeof(int8_t);
            certLengthReduced = YES;
        }
        
        if (certLengthReduced) {
            endByteOfCertificate -= 1;
        }
        
        NSData *responseData = [certDataBlock subdataWithRange:NSMakeRange(0, endByteOfCertificate)];
        response = responseData;
    } failure:^(NSError *error) {
        [NSException raise:@"Decryption failed" format:@""];
    }];
    // Need to wait CardActionsManager response with ACS readers.
    while(!response) {
        [NSThread sleepForTimeInterval:0.05];
    }
    return response;
}
- (NSData*)decrypt:(NSData*)data pin1:(NSString *)pin1 {
    __block NSData *response = nil;
    __block NSString *errorMessage = nil;
    [[CardActionsManager sharedInstance] decryptData:data pin1:pin1 useECC:NO success:^(NSData *certDataBlock){
        response = certDataBlock;
    } failure:^(NSError *error) {
        errorMessage = [self handleErrorMessage:error];
    }];
    // Need to wait CardActionsManager response with ACS readers.
    while(!response) {
        if(errorMessage){
            [NSException raise: errorMessage format:@""];
        }
        [NSThread sleepForTimeInterval:0.1];
    }
    return response;
}

- (NSData*)derive:(NSData*)data pin1:(NSString *)pin1 {
    __block NSData *response = nil;
    __block NSString *errorMessage = nil;
    [[CardActionsManager sharedInstance] decryptData:data pin1:pin1 useECC:YES success:^(NSData *certDataBlock){
        response = certDataBlock;
    } failure:^(NSError *error) {
        errorMessage = [self handleErrorMessage:error];
    }];
    // Need to wait CardActionsManager response with ACS readers.
    while(!response) {
        if(errorMessage){
            [NSException raise: errorMessage format:@""];
        }
        [NSThread sleepForTimeInterval:0.1];
    }
    return response;
}

- (NSString*)handleErrorMessage:(NSError*)error {
    if (error.code == moppLibErrorPinBlocked) {
        return [NSString stringWithFormat:@"%@", @"pin_blocked"];
    } else if (error.code == moppLibErrorWrongPin) {
        NSDictionary *userInfo = [error userInfo];
        for (NSString* key in userInfo) {
            if ([key isEqualToString:@"kMoppLibRetryCount"]) {
                return [NSString stringWithFormat:@"%@ %@", @"wrong_pin", userInfo[key]];
            }
        }
    }
    return [NSString stringWithFormat:@"%@", @"Decryption failed"];
    
}
@end

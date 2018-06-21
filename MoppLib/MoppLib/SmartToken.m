//
//  SmartToken.m
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

#import <Foundation/Foundation.h>
#import "SmartToken.h"
#import "CardActionsManager.h"

@implementation SmartToken

- (NSData*)getCertificate {
    __block NSData *response = nil;
    [[CardActionsManager sharedInstance] authenticationCertDataWithSuccess:^(NSData *certDataBlock){
        const void *bytes = [certDataBlock bytes];
        NSUInteger endByteOfCertificate = [certDataBlock length];
        for (NSUInteger i = [certDataBlock length]-1; i > 0; i -= sizeof(int8_t)) {
            int8_t elem = OSReadLittleInt(bytes, i);
            if(elem != '\0'){
                endByteOfCertificate = i;
                break;
            }
        }
        NSData *responseData = [certDataBlock subdataWithRange:NSMakeRange(0, endByteOfCertificate)];
        
        response = responseData;
    } failure:^(NSError *error) {
        [NSException raise:@"Decryption failed" format:@""];
    }];
    
    return response;
}
- (NSData*)decrypt:(NSData*)data pin1:(NSString *)pin1 {
    __block NSData *response = nil;
    [[CardActionsManager sharedInstance] decryptData:data pin1:pin1 useECC:NO success:^(NSData *certDataBlock){
            response = certDataBlock;
    } failure:^(NSError *error) {
        NSDictionary *userInfo = [error userInfo];
        for (NSString* key in userInfo) {
            if ([key isEqualToString:@"kMoppLibRetryCount"]) {
                [NSException raise:@"wrong_pin" format:@"%@", userInfo[key]];
            }
        }
        [NSException raise:@"Decryption failed" format:@""];
    }];
    return response;
}

- (NSData*)derive:(NSData*)data pin1:(NSString *)pin1 {
    __block NSData *response = nil;
    [[CardActionsManager sharedInstance] decryptData:data pin1:pin1 useECC:YES success:^(NSData *certDataBlock){
        response = certDataBlock;
    } failure:^(NSError *error) {
        NSDictionary *userInfo = [error userInfo];
        for (NSString* key in userInfo) {
            if ([key isEqualToString:@"kMoppLibRetryCount"]) {
                [NSException raise:@"wrong_pin" format:@"%@", userInfo[key]];
            }
        }
        [NSException raise:@"Decryption failed" format:@""];
    }];
    return response;
}

@end

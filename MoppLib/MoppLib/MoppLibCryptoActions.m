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

#import <CryptoLib/CdocParser.h>
#import <MoppLib/MoppLib-Swift.h>

@implementation MoppLibCryptoActions

+ (void)parseCdocInfo:(NSString *)fullPath success:(CdocContainerBlock)success failure:(FailureBlock)failure {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        CdocParser *cdocParser = [CdocParser new];
        CdocInfo *response = [cdocParser parseCdocInfo:fullPath];
        if (response.addressees == nil || response.dataFiles == nil) {
            error = [MoppLibError error:MoppLibErrorCodeGeneral];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            error == nil ? success(response) : failure(error);
        });
    });
}

@end

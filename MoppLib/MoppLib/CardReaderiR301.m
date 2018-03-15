//
//  CardReaderIR301.m
//  MoppLib
//
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

#import "CardReaderiR301.h"
#import <Foundation/Foundation.h>
#import "ReaderInterface.h"
#import "winscard.h"
#import "ft301u.h"
#import "wintypes.h"
#import "NSString+Additions.h"
#import "MoppLibCardReaderManager.h"

@interface CardReaderiR301() <ReaderInterfaceDelegate>
@property (nonatomic, strong) DataSuccessBlock successBlock;
@property (nonatomic, strong) FailureBlock failureBlock;
@property (nonatomic, strong) ReaderInterface *interface;
@property (nonatomic) SCARDHANDLE contextHandle;
@end

@implementation CardReaderiR301

-(id)initWithInterface:(ReaderInterface*)interface
{
    if (self = [super init]) {
        _interface = interface;
        return self;
    }
    return nil;
}

-(void)setupWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    _successBlock = success;
    _failureBlock = failure;
}

#pragma mark - CardReaderWrapper

- (void)transmitCommand:(NSString *)commandHex success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [[MoppLibCardReaderManager sharedInstance] transmitCommand:commandHex success:success failure:failure];
}

- (void)powerOnCard:(DataSuccessBlock)success failure:(FailureBlock)failure  {
    success(nil);
}

- (void)isCardInserted:(void(^)(BOOL)) completion {
    completion(YES);
}

- (BOOL)isConnected {
    return YES;
}

- (void)isCardPoweredOn:(void(^)(BOOL)) completion {
    completion(NO);
}

- (void)resetReader {
}

@end

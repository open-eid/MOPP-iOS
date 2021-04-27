//
//  CardActionsManager.h
//  MoppLib
//
/*
 * Copyright 2021 Riigi Infosüsteemi Amet
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
#import <UIKit/UIKit.h>
#import "CardCommands.h"


@interface CardActionsManager : NSObject
+ (CardActionsManager *)sharedInstance;

@property (nonatomic, strong) id<CardReaderWrapper> reader;

- (void)setReader:(id<CardReaderWrapper>)cardReader;

- (void)minimalCardPersonalDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure;

- (void)cardPersonalDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure;

- (void)signingCertWithPin2:(NSString *)pin2 success:(CertDataBlock)success failure:(FailureBlock)failure;
- (void)authenticationCertWithSuccess:(CertDataBlock)success failure:(FailureBlock)failure;

- (void)authenticationCertDataWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure;
- (void)signingCertDataWithPin2:(NSString *)pin2 success:(DataSuccessBlock)success failure:(FailureBlock)failure;

- (void)changePin:(CodeType)type withPuk:(NSString *)puk to:(NSString *)newPin success:(VoidBlock)success failure:(FailureBlock)failure;

- (void)changeCode:(CodeType)type withVerifyCode:(NSString *)verify to:(NSString *)newCode success:(VoidBlock)success failure:(FailureBlock)failure;

- (void)unblockCode:(CodeType)type withPuk:(NSString *)puk newCode:(NSString *)newCode success:(VoidBlock)success failure:(FailureBlock)failure ;

- (void)code:(CodeType)type retryCountWithSuccess:(NumberBlock)success failure:(FailureBlock)failure;

- (void)addSignature:(NSString *)containerPath withPin2:(NSString *)pin2 success:(void (^)(MoppLibContainer *container, BOOL signatureWasAdded))success failure:(FailureBlock)failure;

- (void)calculateSignatureFor:(NSData *)hash pin2:(NSString *)pin2 useECC:(BOOL)useECC success:(DataSuccessBlock)success failure:(FailureBlock)failure;

- (void)decryptData:(NSData *)hash pin1:(NSString *)pin1 useECC:(BOOL)useECC success:(DataSuccessBlock)success failure:(FailureBlock)failure;

- (void)isCardInserted:(BoolBlock)completion;

- (BOOL)isReaderConnected;

- (void)resetCardActions;
@end

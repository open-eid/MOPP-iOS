//
//  CardActionsManager.m
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

#import "CardActionsManager.h"
#import "CardReaderWrapper.h"
#import "MoppLibError.h"
#import "NSString+Additions.h"
#import "Idemia.h"
#import "MoppLibCardReaderManager.h"

@implementation CardActionsManager {
    id<CardCommands> _cardCommandHandler;
}

+ (CardActionsManager *)sharedInstance {
    static CardActionsManager *sharedInstance = nil;
    if (sharedInstance == nil) {
        sharedInstance = [CardActionsManager new];
    }
    return sharedInstance;
}

- (void)cardPersonalDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure {
    [self executeAction:^(id<CardCommands> handler, FailureBlock failure) {
        [handler readPublicDataWithSuccess:success failure:failure];
    } failure:failure];
}

- (void)signingCertWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self executeAction:^(id<CardCommands> handler, FailureBlock failure) {
        [handler readSignatureCertificateWithSuccess:success failure:failure];
    } failure:failure];
}

- (void)authenticationCertWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self executeAction:^(id<CardCommands> handler, FailureBlock failure) {
        [handler readAuthenticationCertificateWithSuccess:success failure:failure];
    } failure:failure];
}

- (void)changeCode:(CodeType)type withVerifyCode:(NSString *)verify to:(NSString *)newCode success:(VoidBlock)success failure:(FailureBlock)failure {
    [self executeAction:^(id<CardCommands> handler, FailureBlock failure) {
        [handler changeCode:type to:newCode withVerifyCode:verify withSuccess:success failure:failure];
    } failure:failure];
}

- (void)changePin:(CodeType)type withPuk:(NSString *)puk to:(NSString *)newPin success:(VoidBlock)success failure:(FailureBlock)failure {
    [self executeAction:^(id<CardCommands> handler, FailureBlock failure) {
        [handler unblockCode:type withPuk:puk newCode:newPin success:success failure:failure];
    } failure:failure];
}

- (void)unblockCode:(CodeType)type withPuk:(NSString *)puk newCode:(NSString *)newCode success:(VoidBlock)success failure:(FailureBlock)failure {
    [self executeAction:^(id<CardCommands> handler, FailureBlock failure) {
        [handler unblockCode:type withPuk:puk newCode:newCode success:success failure:failure];
    } failure:failure];
}

- (void)code:(CodeType)type retryCountWithSuccess:(void (^)(NSNumber *))success failure:(FailureBlock)failure {
    [self executeAction:^(id<CardCommands> handler, FailureBlock failure) {
        [handler readCodeCounterRecord:type withSuccess:success failure:failure];
    } failure:failure];
}

- (void)authenticateFor:(NSData *)hash pin1:(NSString *)pin1 success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self executeAction:^(id<CardCommands> handler, FailureBlock failure) {
        [handler authenticateFor:hash withPin1:pin1 success:success failure:failure];
    } failure:failure];
}

- (void)calculateSignatureFor:(NSData *)hash pin2:(NSString *)pin2 success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self executeAction:^(id<CardCommands> handler, FailureBlock failure) {
        [handler calculateSignatureFor:hash withPin2:pin2 success:success failure:failure];
    } failure:failure];
}

- (void)decryptData:(NSData *)hash pin1:(NSString *)pin1 success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self executeAction:^(id<CardCommands> handler, FailureBlock failure) {
        [handler decryptData:hash withPin1:pin1 success:success failure:failure];
    } failure:failure];
}

- (void)executeAction:(void (^)(id<CardCommands>, FailureBlock))action failure:(FailureBlock)failure {
    printLog(@"ID-CARD: EXECUTE ACTION");
    if (self.reader == nil || ![self.reader isConnected]) {
        printLog(@"ID-CARD: READER IS NOT CONNECTED");
        [[MoppLibCardReaderManager sharedInstance] stopDiscoveringReadersWithStatus:ReaderProcessFailed];
        failure([MoppLibError readerNotFoundError]);
    } else if (![self.reader isCardInserted]) {
        MLLog(@"ID-CARD: Card not inserted");
        failure([MoppLibError cardNotFoundError]);
    } else if([self.reader isCardPoweredOn]) {
        printLog(@"---| EXECUTE ACTION |---");
        action(_cardCommandHandler, failure);
    } else {
        [_reader powerOnCard:^(NSData* atr) {
            static const NSString *idemiaAtr = @"3B DB 96 00 80 B1 FE 45 1F 83 00 12 23 3F 53 65 49 44 0F 90 00 F1";
            if([atr isEqualToData:[idemiaAtr toHexData]]) {
                self->_cardCommandHandler = [[Idemia alloc] initWithReader:self->_reader];
                printLog(@"---| EXECUTE ACTION |---");
                action(self->_cardCommandHandler, failure);
            } else {
                MLLog(@"ID-CARD: Unable to determine card version");
                failure([MoppLibError cardVersionUnknownError]);
            }
        } failure:^(NSError *error) {
            MLLog(@"Unable to power on card");
            failure([MoppLibError readerProcessFailedError]);
        }];
    }
}

@end

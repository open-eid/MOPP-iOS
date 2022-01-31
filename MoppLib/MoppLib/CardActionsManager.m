//
//  CardActionsManager.m
//  MoppLib
//
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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
#import "CardReaderiR301.h"
#import "ReaderInterface.h"
#import "wintypes.h"
#import "MoppLibError.h"
#import "NSData+Additions.h"
#import "EstEIDv3_4.h"
#import "EstEIDv3_5.h"
#import "Idemia.h"
#import "MoppLibCertificate.h"
#import "MoppLibDigidocManager.h"
#import "MoppLibCardReaderManager.h"
#import <CommonCrypto/CommonDigest.h>

typedef NS_ENUM(NSUInteger, CardAction) {
    CardActionReadMinPublicData = 0,
    CardActionReadPublicData = 1,
    CardActionChangePin = 2,
    CardActionChangePinWithPuk = 3,
    CardActionUnblockPin = 4,
    CardActionPinRetryCount = 5,
    CardActionReadSigningCert = 6,
    CardActionReadAuthenticationCert = 7,
    CardActionReadSecretKey = 8,
    CardActionCalculateSignature = 9,
    CardActionDecryptData = 10,
    CardActionGetCardStatus = 11
};

NSString *const kCardActionDataHash = @"Hash";
NSString *const kCardActionDataCodeType = @"Code type";
NSString *const kCardActionDataNewCode = @"New code";
NSString *const kCardActionDataVerify = @"Verify";
NSString *const kCardActionDataRecord = @"Record";
NSString *const kCardActionDataUseECC = @"Use ECC";

@interface CardActionObject : NSObject
@property (nonatomic, assign) CardAction action;
@property (nonatomic, strong) void (^successBlock)(id);
@property (nonatomic, strong) FailureBlock failureBlock;
@property (nonatomic, strong) BoolBlock completionBlock;
@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, strong) NSString *pin;
@property (nonatomic)         BOOL useECC;
@end

@implementation CardActionObject

@end


@interface CardActionsManager() <CardReaderWrapperDelegate>

@property (nonatomic, strong) NSMutableArray *cardActions;
@property (nonatomic, assign) BOOL isActionExecuting;
@property (nonatomic, strong) id<CardCommands> cardCommandHandler;
@end

@implementation CardActionsManager

static CardActionsManager *sharedInstance = nil;

+ (CardActionsManager *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [CardActionsManager new];
        // FIXME:
        // [[CBManagerHelper sharedInstance] addDelegate:sharedInstance];
    }
    return sharedInstance;
}

- (NSMutableArray *)cardActions {
    if (!_cardActions) {
        [self resetCardActions];
    }
    
    return _cardActions;
}

- (void)resetCardActions {
    _cardActions = [NSMutableArray new];
    _isActionExecuting = NO;
}

- (void)setReader:(id<CardReaderWrapper>)cardReader {
    _reader = cardReader;
    [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationReaderStatusChanged object:nil];
}

- (void)minimalCardPersonalDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure {
    [self addCardAction:CardActionReadMinPublicData data:nil success:success failure:failure];
}

- (void)cardPersonalDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure {
    [self addCardAction:CardActionReadPublicData data:nil success:success failure:failure];
}

- (void)signingCertWithPin2:(NSString *)pin2 success:(CertDataBlock)success failure:(FailureBlock)failure {
    MoppLibCerificatetData *certData = [MoppLibCerificatetData new];
    
    [self signingCertDataWithPin2:pin2 success:^(NSData *data) {
        [MoppLibCertificate certData:certData updateWithDerEncodingData:[data bytes] length:[data length]];
        success(certData);
    } failure:failure];
}

- (void)signingCertDataWithPin2:(NSString *)pin2 success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self addCardAction:CardActionReadSigningCert data:@{kCardActionDataVerify: pin2} success:success failure:failure];
}

- (void)authenticationCertWithSuccess:(CertDataBlock)success failure:(FailureBlock)failure {
    MoppLibCerificatetData *certData = [MoppLibCerificatetData new];
    
    [self authenticationCertDataWithSuccess:^(NSData *data) {
        [MoppLibCertificate certData:certData updateWithDerEncodingData:[data bytes] length:data.length];

        success(certData);
    } failure:failure];
}

- (void)authenticationCertDataWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self addCardAction:CardActionReadAuthenticationCert data:nil success:success failure:failure];
}

- (void)changeCode:(CodeType)type withVerifyCode:(NSString *)verify to:(NSString *)newCode success:(VoidBlock)success failure:(FailureBlock)failure {
    NSDictionary *data = @{kCardActionDataCodeType:[NSNumber numberWithInt:type], kCardActionDataVerify:verify, kCardActionDataNewCode:newCode};
    [self addCardAction:CardActionChangePin data:data success:^(id data) {
        success();
    } failure:failure];
}

- (void)changePin:(CodeType)type withPuk:(NSString *)puk to:(NSString *)newPin success:(VoidBlock)success failure:(FailureBlock)failure {
    NSDictionary *data = @{kCardActionDataCodeType:[NSNumber numberWithInt:type], kCardActionDataVerify:puk, kCardActionDataNewCode:newPin};
    [self addCardAction:CardActionChangePinWithPuk data:data success:^(id data) {
        success();
    } failure:failure];
}

- (void)code:(CodeType)type retryCountWithSuccess:(void (^)(NSNumber *))success failure:(FailureBlock)failure {
    NSDictionary *data = @{kCardActionDataCodeType:[NSNumber numberWithInt:type]};
    [self addCardAction:CardActionPinRetryCount data:data success:success failure:failure];
}

- (void)unblockCode:(CodeType)type withPuk:(NSString *)puk newCode:(NSString *)newCode success:(VoidBlock)success failure:(FailureBlock)failure {
    NSDictionary *data = @{kCardActionDataCodeType:[NSNumber numberWithInt:type], kCardActionDataVerify:puk, kCardActionDataNewCode:newCode};
    [self addCardAction:CardActionUnblockPin data:data success:^(id data) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationRetryCounterChanged object:nil];
        success();
    } failure:failure];
}

- (void)calculateSignatureFor:(NSData *)hash pin2:(NSString *)pin2 useECC:(BOOL)useECC success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    NSDictionary *data = @{kCardActionDataHash:hash, kCardActionDataVerify:pin2, kCardActionDataUseECC:[NSNumber numberWithBool:useECC]};
    [self addCardAction:CardActionCalculateSignature data:data success:success failure:failure];
}

- (void)decryptData:(NSData *)hash pin1:(NSString *)pin1 useECC:(BOOL)useECC success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    NSDictionary *data = @{kCardActionDataHash:hash, kCardActionDataVerify:pin1, kCardActionDataUseECC:[NSNumber numberWithBool:useECC]};
     [self addCardAction:CardActionDecryptData data:data success:success failure:failure];
}

- (void)addSignature:(NSString *)containerPath withPin2:(NSString *)pin2 success:(void(^)(MoppLibContainer *container, BOOL signatureWasAdded))success failure:(FailureBlock)failure {
    
    [self code:CodeTypePin2 retryCountWithSuccess:^(NSNumber *count) {
        if (count.intValue > 0) {
            __weak typeof(self) weakSelf = self;
            [weakSelf addSignatureTo:containerPath pin2:pin2 success:success andFailure:failure];

        } else {
            failure([MoppLibError pinBlockedError]);
        }
    } failure:failure];
}

- (void)addSignatureTo:(NSString *)containerPath pin2:(NSString *)pin2 success:(void(^)(MoppLibContainer *container, BOOL signatureWasAdded))success andFailure:(FailureBlock)failure {
    [self signingCertDataWithPin2:pin2 success:^(NSData *certData) {
        [[MoppLibDigidocManager sharedInstance] addSignature:containerPath pin2:pin2 cert:certData success:^(MoppLibContainer *container) {
            success(container, YES);
        } andFailure:failure];
    } failure:failure];
}

- (void)notifyIdNeeded:(NSError *)error {
    if (error.code == moppLibErrorWrongPin) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationRetryCounterChanged object:nil];
    }
}

/**
 * Adds card action to queue. One card action may require sending multiple commands to id card. These commands often must be executed in specific order. For that reason we must make sure commands from different card actions are not mixed.
 *
 * @param action    card action to be added to execution queue
 * @param success   block to be called when card action is completed successfully
 * @param failure   block to be called when executing card action fails
 */
- (void)addCardAction:(NSUInteger)action data:(NSDictionary *)data success:(void (^)(id))success failure:(FailureBlock)failure {
    NSLog(@"addCardAction");
    @synchronized (self) {
        CardActionObject *cardAction = [CardActionObject new];
        cardAction.successBlock = success;
        cardAction.failureBlock = ^(NSError *error) {
            [self notifyIdNeeded:error];
            failure(error);
        };
        cardAction.action = action;
        cardAction.data = data;
        cardAction.retryCount = 0;
        
        [self.cardActions addObject:cardAction];
        [self executeNextAction];
    }
}


- (void)executeNextAction {
    NSLog(@"EXECUTE NEXT ACTION");
    @synchronized (self) {
        if (self.cardActions.count > 0 && !self.isActionExecuting) {
            [[MoppLibCardReaderManager sharedInstance] resetReaderRestart];
            NSLog(@"ID-CARD: Currently executing card action");
            self.isActionExecuting = YES;
            CardActionObject *action = self.cardActions.firstObject;
            [self executeAfterReaderCheck:action apduLength:0];
        } else {
            NSLog(@"Error executing next action: cardActions.count=%lu isExecutingAction=%i", (unsigned long)self.cardActions.count, self.isActionExecuting);
        }
    }
}

- (void)executeAfterReaderCheck:(CardActionObject *)action apduLength:(unsigned char)apduLength {
    NSLog(@"EXECUTE AFTER READER CHECK");
    if (![self isReaderConnected]) {
        NSLog(@"ID-CARD: READER IS NOT CONNECTED");
        if (action.completionBlock == nil) {
            [[MoppLibCardReaderManager sharedInstance] resetReaderRestart];
            [[MoppLibCardReaderManager sharedInstance] restartDiscoveringReaders:2.0f];
            return;
        }
        action.completionBlock(NO);
        [self finishCurrentAction];
        return;
    }

    [self.reader isCardInserted:^(BOOL isInserted) {
        NSLog(@"ID-CARD: Is card inserted: %d", isInserted);
        if (action.action == CardActionGetCardStatus) {
            action.completionBlock(isInserted);
            [self finishCurrentAction];
            return;
        }
        if (isInserted) {
            [self.reader isCardPoweredOn:^(BOOL isPoweredOn) {
                if (isPoweredOn) {
                    NSLog(@"---| EXECUTE ACTION |---");
                    [self executeAction:action];
                } else {
                    [self processAction:action apduLength:apduLength];
                }
            }];
        } else {
            MLLog(@"Card not inserted");
            action.failureBlock([MoppLibError cardNotFoundError]);
            [self finishCurrentAction];
        }
    }];
}

- (void)processAction:(CardActionObject *)actionObject apduLength:(unsigned char)apduLength {
    [_reader powerOnCard:^(NSData* powerData) {
    
        switch (self->_reader.cardChipType) {
        case ChipType_EstEID35: {
                EstEIDv3_5 *handler = [EstEIDv3_5 new];
            [handler setReader:self->_reader];
            self->_cardCommandHandler = handler;
            }
            break;
        case ChipType_EstEID34: {
                EstEIDv3_4 *handler = [EstEIDv3_4 new];
            [handler setReader:self->_reader];
            self->_cardCommandHandler = handler;
            }
            break;
        case ChipType_Idemia: {
                Idemia *handler = [Idemia new];
            [handler setReader:self->_reader];
            self->_cardCommandHandler = handler;
            }
            break;
        default: {
                MLLog(@"Unable to determine card version");
                actionObject.failureBlock([MoppLibError cardVersionUnknownError]);
                [self finishCurrentAction];
                return;
            }
            break;
        }
    
        [self executeAction:actionObject];
        
    } failure:^(NSError *error) {
        MLLog(@"Unable to power on card");
        actionObject.failureBlock([MoppLibError cardNotFoundError]);
        [[MoppLibCardReaderManager sharedInstance] restartDiscoveringReaders:2.0f];
        [self finishCurrentAction];
    }];
}


- (void)executeAction:(CardActionObject *)actionObject {
    if (!self.cardCommandHandler) {
        // Something went wrong with reader setup. Let's make another round
        _reader = nil;
        [self executeAfterReaderCheck:actionObject apduLength:0];
        return;
    }
    
    void (^success)(id) = ^void (id response) {
        actionObject.successBlock(response);
        [self finishCurrentAction];
    };
    
    void (^failure)(id) = ^void (NSError *error) {
        if (error.code == 5 && actionObject.retryCount < 1) {
            actionObject.retryCount = actionObject.retryCount + 1;
            
            // Could be caused bu card change and card is not powered on
            [self.reader powerOnCard:^(NSData* powerData){
                [self executeAction:actionObject];
            } failure:^(NSError *error) {
                actionObject.failureBlock(error);
                [self finishCurrentAction];
            }];
            
        } else {
            actionObject.failureBlock(error);
            [self finishCurrentAction];
        }
    };
    
    switch (actionObject.action) {
        case CardActionReadPublicData: {
            [self.cardCommandHandler readPublicDataWithSuccess:success failure:failure];
            break;
        }
            
        case CardActionReadMinPublicData: {
            [self.cardCommandHandler readMinimalPublicDataWithSuccess:success failure:failure];
            break;
        }
            
        case CardActionChangePin: {
            CodeType type = ((NSNumber *)[actionObject.data objectForKey:kCardActionDataCodeType]).integerValue;
            NSString *verifyCode = [actionObject.data objectForKey:kCardActionDataVerify];
            NSString *newCode = [actionObject.data objectForKey:kCardActionDataNewCode];
            [self.cardCommandHandler changeCode:type to:newCode withVerifyCode:verifyCode withSuccess:success failure:failure];
            break;
        }
            
        case CardActionChangePinWithPuk: {
            CodeType type = ((NSNumber *)[actionObject.data objectForKey:kCardActionDataCodeType]).integerValue;
            NSString *verifyCode = [actionObject.data objectForKey:kCardActionDataVerify];
            NSString *newCode = [actionObject.data objectForKey:kCardActionDataNewCode];
            
            // Changing PIN with PUK requires blocking PIN and then performing unblock action. To make sure we don't block PIN without reason, we will verify PUK first.
            [self.cardCommandHandler verifyCode:verifyCode ofType:CodeTypePuk withSuccess:^(NSData *data) {
                [self blockPin:type completion:^{
                    [self.cardCommandHandler unblockCode:type withPuk:verifyCode newCode:newCode success:success failure:failure];
                }];
            } failure:failure];
            break;
        }
            
        case CardActionUnblockPin: {
            CodeType type = ((NSNumber *)[actionObject.data objectForKey:kCardActionDataCodeType]).integerValue;
            NSString *pin = [actionObject.data objectForKey:kCardActionDataNewCode];
            NSString *puk = [actionObject.data objectForKey:kCardActionDataVerify];
            [self.cardCommandHandler unblockCode:type withPuk:puk newCode:pin success:success failure:failure];
            break;
        }
            
        case CardActionPinRetryCount: {
            CodeType type = ((NSNumber *)[actionObject.data objectForKey:kCardActionDataCodeType]).integerValue;
            
            [self.cardCommandHandler readCodeCounterRecord:type withSuccess:^(NSNumber *data) {
                success(data);
            } failure:failure];
            break;
        }
            
        case CardActionReadSigningCert: {
            [self readCert:CardActionReadSigningCert success:success failure:failure];
            break;
        }
        case CardActionReadAuthenticationCert: {
            [self readCert:CardActionReadAuthenticationCert success:success failure:failure];
            break;
        }
            
        case CardActionCalculateSignature: {
            NSString *pin2 = [actionObject.data objectForKey:kCardActionDataVerify];
            NSData *hash = [actionObject.data objectForKey:kCardActionDataHash];
            BOOL useECC = [(NSNumber *)[actionObject.data objectForKey:kCardActionDataUseECC] boolValue];
            [self.cardCommandHandler calculateSignatureFor:hash withPin2:pin2 useECC:useECC success:success failure:failure];
            break;
        }
        
        case CardActionDecryptData: {
            NSString *pin1 = [actionObject.data objectForKey:kCardActionDataVerify];
            NSData *hash = [actionObject.data objectForKey:kCardActionDataHash];
            BOOL useECC = [(NSNumber *)[actionObject.data objectForKey:kCardActionDataUseECC] boolValue];
            [self.cardCommandHandler decryptData:hash withPin1:pin1 useECC:useECC success:success failure:failure];
            break;
        }
            
        case CardActionReadSecretKey: {
            NSNumber *record = [actionObject.data objectForKey:kCardActionDataRecord];
            [self.cardCommandHandler readSecretKeyRecord:record.integerValue withSuccess:success failure:failure];
            break;
        }
            
        default:
            break;
    }
}

- (void) blockPin:(CodeType)pinId completion:(VoidBlock)completion {
    [self blockPin:pinId withCode:@"00000" completion:completion];
}

NSString *blockBackupCode = @"00001";
- (void)blockPin:(CodeType)pinId withCode:(NSString *)code completion:(VoidBlock)completion {
    void (^failure)(NSError *) = ^(NSError *error) {
        if (error.code == moppLibErrorWrongPin) {
            NSNumber *count = [error.userInfo objectForKey:kMoppLibUserInfoRetryCount];
            if (count.intValue > 0) {
                [self blockPin:pinId completion:completion];
            } else {
                completion();
            }
        } else {
            completion();
        }
    };
    
    void (^success)(NSData *) = ^(NSData *data) {
        if ([code isEqualToString:blockBackupCode]) {
            [self blockPin:pinId withCode:blockBackupCode completion:completion];
        } else {
            // This should not happen
            completion();
        }
    };
    
    if (pinId == 1) {
        [self.cardCommandHandler verifyCode:code ofType:CodeTypePin1 withSuccess:success failure:failure];
    } else {
        [self.cardCommandHandler verifyCode:code ofType:CodeTypePin2 withSuccess:success failure:failure];
    }
}

- (void)readCert:(CardAction)certAction success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    
    if (certAction == CardActionReadSigningCert) {
        [self.cardCommandHandler readSignatureCertificateWithSuccess:success failure:failure];
    } else if (certAction == CardActionReadAuthenticationCert) {
        [self.cardCommandHandler readAuthenticationCertificateWithSuccess:success failure:failure];
    }
    
}

- (void)finishCurrentAction {
    @synchronized (self) {
        if (self.isActionExecuting) {
            self.isActionExecuting = NO;
            [self.cardActions removeObject:self.cardActions.firstObject];
        }
        
        [self executeNextAction];
    }
}

- (BOOL)isReaderConnected {
    if (self.reader == nil) {
        return false;
    }
    return self.reader && [self.reader isConnected];
}

- (void)isCardInserted:(BoolBlock) completion {
    @synchronized (self) {
        CardActionObject *actionObject = [CardActionObject new];
        actionObject.completionBlock = completion;
        actionObject.action = CardActionGetCardStatus;
        
        [self.cardActions addObject:actionObject];
        [self executeNextAction];
    }
}

#pragma mark - ReaderSelectionViewControllerDelegate

- (void)cancelledReaderSelection {
    if (self.isActionExecuting) {
        [self clearActionsWithError:[MoppLibError readerSelectionCanceledError]];
    }
}

- (void)clearActionsWithError:(NSError *)error {
    self.isActionExecuting = NO;
    
    while (self.cardActions.count > 0) {
        CardActionObject *action = [self.cardActions firstObject];
        if (action.failureBlock) {
            action.failureBlock(error);
        } else if (action.completionBlock) {
            action.completionBlock(NO);
        }
        [self.cardActions removeObject:action];
    }
}

#pragma mark - CardReaderWrapperDelegate

- (void)cardStatusUpdated:(CardStatus)status {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationReaderStatusChanged object:nil];
    
    if (status == CardStatusAbsent) {
        //Making sure we don't get stuck with some action, that can't be completed anymore
        [self.reader resetReader];
        [self clearActionsWithError:[MoppLibError cardNotFoundError]];
    }
}
@end


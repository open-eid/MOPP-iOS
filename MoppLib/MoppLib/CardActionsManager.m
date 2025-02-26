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
#import "ReaderInterface.h"
#import "MoppLibError.h"
#import "Idemia.h"
#import "MoppLibDigidocManager.h"
#import "MoppLibCardReaderManager.h"

typedef NS_ENUM(NSUInteger, CardAction) {
    CardActionReadPublicData = 1,
    CardActionChangePin = 2,
    CardActionChangePinWithPuk = 3,
    CardActionUnblockPin = 4,
    CardActionPinRetryCount = 5,
    CardActionReadSigningCert = 6,
    CardActionReadAuthenticationCert = 7,
    CardActionCalculateSignature = 9,
    CardActionDecryptData = 10,
    CardActionGetCardStatus = 11,
    CardActionAuth = 12,
};

NSString *const kCardActionDataHash = @"Hash";
NSString *const kCardActionDataCodeType = @"Code type";
NSString *const kCardActionDataNewCode = @"New code";
NSString *const kCardActionDataVerify = @"Verify";

@interface CardActionObject : NSObject
@property (nonatomic, assign) CardAction action;
@property (nonatomic, strong) void (^successBlock)(id);
@property (nonatomic, strong) FailureBlock failureBlock;
@property (nonatomic, strong) BoolBlock completionBlock;
@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, strong) NSString *pin;
@end

@implementation CardActionObject

@end


@interface CardActionsManager()

@property (nonatomic, strong) NSMutableArray *cardActions;
@property (nonatomic, assign) BOOL isActionExecuting;
@property (nonatomic, strong) id<CardCommands> cardCommandHandler;
@property (nonatomic, assign) BOOL didReaderRestart;
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
}

- (void)cardPersonalDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure {
    [self addCardAction:CardActionReadPublicData data:nil success:success failure:failure];
}

- (void)signingCertWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self addCardAction:CardActionReadSigningCert data:nil success:success failure:failure];
}

- (void)authenticationCertWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
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
        success();
    } failure:failure];
}

- (void)authenticateFor:(NSData *)hash pin1:(NSString *)pin1 success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    NSDictionary *data = @{kCardActionDataHash:hash, kCardActionDataVerify:pin1};
    [self addCardAction:CardActionAuth data:data success:success failure:failure];
}

- (void)calculateSignatureFor:(NSData *)hash pin2:(NSString *)pin2 success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    NSDictionary *data = @{kCardActionDataHash:hash, kCardActionDataVerify:pin2};
    [self addCardAction:CardActionCalculateSignature data:data success:success failure:failure];
}

- (void)decryptData:(NSData *)hash pin1:(NSString *)pin1 success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    NSDictionary *data = @{kCardActionDataHash:hash, kCardActionDataVerify:pin1};
    [self addCardAction:CardActionDecryptData data:data success:success failure:failure];
}

- (void)addSignature:(NSString *)containerPath withPin2:(NSString *)pin2 roleData:(MoppLibRoleAddressData *)roleData success:(void(^)(MoppLibContainer *container, BOOL signatureWasAdded))success failure:(FailureBlock)failure {

    [self code:CodeTypePin2 retryCountWithSuccess:^(NSNumber *count) {
        if (count.intValue > 0) {
            __weak typeof(self) weakSelf = self;
            [weakSelf addSignatureTo:containerPath pin2:pin2 roleData:roleData success:success andFailure:failure];

        } else {
            failure([MoppLibError pinBlockedError]);
        }
    } failure:failure];
}

- (void)addSignatureTo:(NSString *)containerPath pin2:(NSString *)pin2 roleData:(MoppLibRoleAddressData *)roleData success:(void(^)(MoppLibContainer *container, BOOL signatureWasAdded))success andFailure:(FailureBlock)failure {
    [self signingCertWithSuccess:^(NSData *certData) {
        [[MoppLibDigidocManager sharedInstance] addSignature:containerPath pin2:pin2 cert:certData roleData:roleData success:^(MoppLibContainer *container) {
            success(container, YES);
        } andFailure:failure];
    } failure:failure];
}

/**
 * Adds card action to queue. One card action may require sending multiple commands to id card. These commands often must be executed in specific order. For that reason we must make sure commands from different card actions are not mixed.
 *
 * @param action    card action to be added to execution queue
 * @param success   block to be called when card action is completed successfully
 * @param failure   block to be called when executing card action fails
 */
- (void)addCardAction:(NSUInteger)action data:(NSDictionary *)data success:(void (^)(id))success failure:(FailureBlock)failure {
    printLog(@"addCardAction");
    @synchronized (self) {
        CardActionObject *cardAction = [CardActionObject new];
        cardAction.successBlock = success;
        cardAction.failureBlock = ^(NSError *error) {
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
    printLog(@"EXECUTE NEXT ACTION");
    @synchronized (self) {
        if (self.cardActions.count > 0 && !self.isActionExecuting) {
            printLog(@"ID-CARD: No card actions.");
            printLog(@"ID-CARD: Currently executing card action");
            self.isActionExecuting = YES;
            CardActionObject *action = self.cardActions.firstObject;
            [self executeAfterReaderCheck:action apduLength:0];
        } else {
            printLog(@"Error executing next action: cardActions.count=%lu isExecutingAction=%i", (unsigned long)self.cardActions.count, self.isActionExecuting);
        }
    }
}

- (void)executeAfterReaderCheck:(CardActionObject *)action apduLength:(unsigned char)apduLength {
    printLog(@"ID-CARD: EXECUTE AFTER READER CHECK");
    if (![self isReaderConnected]) {
        printLog(@"ID-CARD: READER IS NOT CONNECTED");
        if (action.completionBlock == nil) {
            printLog(@"ID-CARD: executeAfterReaderCheck. Resetting reader restart and stopping discovering readers");
            [[MoppLibCardReaderManager sharedInstance] resetReaderRestart];
            [[MoppLibCardReaderManager sharedInstance] stopDiscoveringReadersWithStatus:ReaderProcessFailed];
            return;
        }
        action.completionBlock(NO);
        [self finishCurrentAction];
        return;
    }

    [self.reader isCardInserted:^(BOOL isInserted) {
        printLog(@"ID-CARD: Is card inserted: %d", isInserted);
        if (action.action == CardActionGetCardStatus) {
            action.completionBlock(isInserted);
            [self finishCurrentAction];
            return;
        }
        if (isInserted) {
            [self.reader isCardPoweredOn:^(BOOL isPoweredOn) {
                if (isPoweredOn) {
                    printLog(@"---| EXECUTE ACTION |---");
                    [self executeAction:action];
                } else {
                    [self processAction:action apduLength:apduLength];
                }
            }];
        } else {
            MLLog(@"ID-CARD: Card not inserted");
            action.failureBlock([MoppLibError cardNotFoundError]);
            [self finishCurrentAction];
        }
    }];
}

- (void)processAction:(CardActionObject *)actionObject apduLength:(unsigned char)apduLength {
    [_reader powerOnCard:^(NSData* powerData) {

        switch (self->_reader.cardChipType) {
        case ChipType_Idemia: {
                Idemia *handler = [Idemia new];
                [handler setReader:self->_reader];
                self->_cardCommandHandler = handler;
            }
            break;
        default: {
                MLLog(@"ID-CARD: Unable to determine card version");
                actionObject.failureBlock([MoppLibError cardVersionUnknownError]);
                [self finishCurrentAction];
                return;
            }
            break;
        }

        [self executeAction:actionObject];

    } failure:^(NSError *error) {
        MLLog(@"Unable to power on card");
        if (self->_didReaderRestart) {
            [self finishCurrentAction];
            actionObject.failureBlock([MoppLibError readerProcessFailedError]);
            return;
        }
        self->_didReaderRestart = TRUE;
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
            [self.cardCommandHandler unblockCode:type withPuk:verifyCode newCode:newCode success:success failure:failure];
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
            [self.cardCommandHandler readSignatureCertificateWithSuccess:success failure:failure];
            break;
        }
        case CardActionReadAuthenticationCert: {
            [self.cardCommandHandler readAuthenticationCertificateWithSuccess:success failure:failure];
            break;
        }

        case CardActionCalculateSignature: {
            NSString *pin2 = [actionObject.data objectForKey:kCardActionDataVerify];
            NSData *hash = [actionObject.data objectForKey:kCardActionDataHash];
            [self.cardCommandHandler calculateSignatureFor:hash withPin2:pin2 success:success failure:failure];
            break;
        }

        case CardActionAuth: {
            NSString *pin1 = [actionObject.data objectForKey:kCardActionDataVerify];
            NSData *hash = [actionObject.data objectForKey:kCardActionDataHash];
            [self.cardCommandHandler authenticateFor:hash withPin1:pin1 success:success failure:failure];
            break;
        }

        case CardActionDecryptData: {
            NSString *pin1 = [actionObject.data objectForKey:kCardActionDataVerify];
            NSData *hash = [actionObject.data objectForKey:kCardActionDataHash];
            [self.cardCommandHandler decryptData:hash withPin1:pin1 success:success failure:failure];
            break;
        }

        default:
            break;
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
    if (status == CardStatusAbsent) {
        //Making sure we don't get stuck with some action, that can't be completed anymore
        [self.reader resetReader];
        [self clearActionsWithError:[MoppLibError cardNotFoundError]];
    }
}
@end

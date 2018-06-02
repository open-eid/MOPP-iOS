//
//  CardActionsManager.m
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

#import "CardActionsManager.h"
#import "CardReaderACR3901U_S1.h"
#import "CardReaderiR301.h"
#import "ReaderInterface.h"
#import "wintypes.h"
#import "MoppLibError.h"
#import "NSData+Additions.h"
#import "EstEIDv3_4.h"
#import "EstEIDv3_5.h"
#import "MoppLibCertificate.h"
#import "MoppLibDigidocManager.h"
#import <CommonCrypto/CommonDigest.h>

typedef NS_ENUM(NSUInteger, CardAction) {
    CardActionReadMinPublicData,
    CardActionReadPublicData,
    CardActionChangePin,
    CardActionChangePinWithPuk,
    CardActionUnblockPin,
    CardActionPinRetryCount,
    CardActionReadSigningCert,
    CardActionReadAuthenticationCert,
    CardActionReadOwnerBirthDate,
    CardActionReadSecretKey,
    CardActionCalculateSignature,
    CardActionGetCardStatus
};

NSString *const kCardActionDataHash = @"Hash";
NSString *const kCardActionDataCodeType = @"Code type";
NSString *const kCardActionDataNewCode = @"New code";
NSString *const kCardActionDataVerify = @"Verify";
NSString *const kCardActionDataRecord = @"Record";
NSString *const kCardActionDataUseECC = @"Use ECC";

@interface CardActionObject : NSObject
@property (nonatomic, assign) CardAction cardAction;
@property (nonatomic, strong) void (^successBlock)(id);
@property (nonatomic, strong) FailureBlock failureBlock;
@property (nonatomic, strong) BoolBlock boolBlock;
@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, strong) NSString *pin;
@property (nonatomic)         BOOL useECC;
@end

@implementation CardActionObject

@end


@interface CardActionsManager() <CardReaderWrapperDelegate>

@property (nonatomic, strong) NSMutableArray *cardActions;
@property (nonatomic, assign) BOOL isExecutingAction;
@property (nonatomic, strong) id<CardCommands> cardVersionHandler;
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
    _isExecutingAction = NO;
}

- (void)setCardReader:(id<CardReaderWrapper>)cardReader {
    _cardReader = cardReader;
    [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationReaderStatusChanged object:nil];
}

- (void)minimalCardPersonalDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure {
    [self addCardAction:CardActionReadMinPublicData data:nil success:success failure:failure];
}

- (void)cardPersonalDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure {
    [self addCardAction:CardActionReadPublicData data:nil success:success failure:failure];
}

- (void)cardOwnerBirthDateWithSuccess:(void(^)(NSDate *date))success failure:(FailureBlock)failure {
    [self addCardAction:CardActionReadOwnerBirthDate data:nil success:success failure:failure];
    
}

- (void)signingCertWithPin2:(NSString *)pin2 success:(CertDataBlock)success failure:(FailureBlock)failure {
    
    MoppLibCerificatetData *certData = [MoppLibCerificatetData new];
    
    [self signingCertDataWithPin2:pin2 success:^(NSData *data) {
        [MoppLibCertificate certData:certData updateWithData:[data bytes] length:data.length];
        success(certData);
    } failure:failure];
}

- (void)signingCertDataWithPin2:(NSString *)pin2 success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self addCardAction:CardActionReadSigningCert data:@{kCardActionDataVerify: pin2} success:success failure:failure];
}

- (void)authenticationCertWithSuccess:(CertDataBlock)success failure:(FailureBlock)failure {
    MoppLibCerificatetData *certData = [MoppLibCerificatetData new];
    
    [self authenticationCertDataWithSuccess:^(NSData *data) {
        [MoppLibCertificate certData:certData updateWithData:[data bytes] length:data.length];
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
        CardActionObject *actionObject = [CardActionObject new];
        actionObject.successBlock = success;
        actionObject.failureBlock = ^(NSError *error) {
            [self notifyIdNeeded:error];
            failure(error);
        };
        actionObject.cardAction = action;
        actionObject.data = data;
        actionObject.retryCount = 0;
        
        [self.cardActions addObject:actionObject];
        [self executeNextAction];
    }
}


- (void)executeNextAction {
    @synchronized (self) {
        if (self.cardActions.count > 0 && !self.isExecutingAction) {
            self.isExecutingAction = YES;
            CardActionObject *action = self.cardActions.firstObject;
            [self executeAfterReaderCheck:action abduLength:0];
        } else {
            NSLog(@"Error executing next action: cardActions.count=%lu isExecutingAction=%i", (unsigned long)self.cardActions.count, self.isExecutingAction);
        }
    }
}

- (void)executeAfterReaderCheck:(CardActionObject *)action abduLength:(unsigned char)length {
    if ([self isReaderConnected]) {
        [self.cardReader isCardInserted:^(BOOL isInserted) {
            
            if (action.cardAction == CardActionGetCardStatus) {
                action.boolBlock(isInserted);
                [self finishCurrentAction];
                return;
            }
            
            if (isInserted) {
                [self.cardReader isCardPoweredOn:^(BOOL isPoweredOn) {
                    //if (isPoweredOn) {
                    //    [self executeAction:action];
                    //} else {
                        [self.cardReader powerOnCard:^(NSData* powerData) {
                            NSString *hexCommand = [kCommandGetCardVersion replaceHexStringLastValue:length];
                            [self.cardReader transmitCommand:hexCommand success:^(NSData *responseObject) {
                                NSData *trailerData = [responseObject responseTrailerData];
                                const unsigned char *trailer = [trailerData bytes];
                                
                                // if '6C XY' :Y´ Send same command with Le = ’XY’
                                if (trailerData.length >=2 && trailer[0] == 0x6C) {
                                    unsigned char newLe = trailer[1];
                                    [self executeAfterReaderCheck:action abduLength:newLe];
                                    return;
                                }
                                
                                if (trailerData.length >= 2 && trailer[0] == 0x90 && trailer[1] == 0x00) {
                                    const unsigned char *responseBytes = [responseObject bytes];
                                    
                                    if (responseBytes[0] == 0x03 && responseBytes[1] == 0x05) {
                                        EstEIDv3_5 *handler = [EstEIDv3_5 new];
                                        [handler setReader:self.cardReader];
                                        self.cardVersionHandler = handler;
                                        
                                    } else if (responseBytes[0] == 0x03 && responseBytes[1] == 0x04) {
                                        EstEIDv3_4 *handler = [EstEIDv3_4 new];
                                        [handler setReader:self.cardReader];
                                        self.cardVersionHandler = handler;
                                        
                                    } else {
                                        EstEIDv3_5 *handler = [EstEIDv3_5 new];
                                        [handler setReader:self.cardReader];
                                        self.cardVersionHandler = handler;
                                        
                                    }
                                }
                                
                                [self executeAction:action];
                                
                            } failure:^(NSError *error) {
                                MLLog(@"Unable to determine card version");
                                action.failureBlock([MoppLibError cardVersionUnknownError]);
                                [self finishCurrentAction];
                            }];
                            
                        } failure:^(NSError *error) {
                            MLLog(@"Unable to power on card");
                            action.failureBlock([MoppLibError cardNotFoundError]);
                            [self finishCurrentAction];
                        }];
                    //}
                }];
                
            } else { // !isInserted
                MLLog(@"Card not inserted");
                action.failureBlock([MoppLibError cardNotFoundError]);
                [self finishCurrentAction];
            }
        }]; // [self.cardReader isCardInserted:^(BOOL isInserted) {
        
    } else { // ![self isReaderConnected]
        assert(action.boolBlock != nil);
        action.boolBlock(NO);
        [self finishCurrentAction];
    }
}

- (void)executeAction:(CardActionObject *)actionObject {
    if (!self.cardVersionHandler) {
        // Something went wrong with reader setup. Let's make another round
        // self.cardReader = nil;
        [self executeAfterReaderCheck:actionObject abduLength:0];
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
            [self.cardReader powerOnCard:^(NSData* powerData){
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
    
    switch (actionObject.cardAction) {
        case CardActionReadPublicData: {
            [self.cardVersionHandler readPublicDataWithSuccess:success failure:failure];
            break;
        }
            
        case CardActionReadMinPublicData: {
            [self.cardVersionHandler readMinimalPublicDataWithSuccess:success failure:failure];
            break;
        }
            
        case CardActionChangePin: {
            CodeType type = ((NSNumber *)[actionObject.data objectForKey:kCardActionDataCodeType]).integerValue;
            NSString *verifyCode = [actionObject.data objectForKey:kCardActionDataVerify];
            NSString *newCode = [actionObject.data objectForKey:kCardActionDataNewCode];
            [self.cardVersionHandler changeCode:type to:newCode withVerifyCode:verifyCode withSuccess:success failure:failure];
            break;
        }
            
        case CardActionChangePinWithPuk: {
            CodeType type = ((NSNumber *)[actionObject.data objectForKey:kCardActionDataCodeType]).integerValue;
            NSString *verifyCode = [actionObject.data objectForKey:kCardActionDataVerify];
            NSString *newCode = [actionObject.data objectForKey:kCardActionDataNewCode];
            
            // Changing PIN with PUK requires blocking PIN and then performing unblock action. To make sure we don't block PIN without reason, we will verify PUK first.
            [self.cardVersionHandler verifyCode:verifyCode ofType:CodeTypePuk withSuccess:^(NSData *data) {
                [self blockPin:type completion:^{
                    [self.cardVersionHandler unblockCode:type withPuk:verifyCode newCode:newCode success:success failure:failure];
                }];
            } failure:failure];
            break;
        }
            
        case CardActionUnblockPin: {
            CodeType type = ((NSNumber *)[actionObject.data objectForKey:kCardActionDataCodeType]).integerValue;
            NSString *pin = [actionObject.data objectForKey:kCardActionDataNewCode];
            NSString *puk = [actionObject.data objectForKey:kCardActionDataVerify];
            [self.cardVersionHandler unblockCode:type withPuk:puk newCode:pin success:success failure:failure];
            break;
        }
            
        case CardActionPinRetryCount: {
            CodeType type = ((NSNumber *)[actionObject.data objectForKey:kCardActionDataCodeType]).integerValue;
            
            [self.cardVersionHandler readCodeCounterRecord:type withSuccess:^(NSData *data) {
                success([self retryCountFromData:data]);
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
            
        case CardActionReadOwnerBirthDate: {
            [self.cardVersionHandler readBirthDateWithSuccess:success failure:failure];
            break;
        }
            
        case CardActionCalculateSignature: {
            NSString *pin2 = [actionObject.data objectForKey:kCardActionDataVerify];
            NSData *hash = [actionObject.data objectForKey:kCardActionDataHash];
            BOOL useECC = [(NSNumber *)[actionObject.data objectForKey:kCardActionDataUseECC] boolValue];
            [self.cardVersionHandler calculateSignatureFor:hash withPin2:pin2 useECC:useECC success:success failure:failure];
            break;
        }
            
        case CardActionReadSecretKey: {
            NSNumber *record = [actionObject.data objectForKey:kCardActionDataRecord];
            [self.cardVersionHandler readSecretKeyRecord:record.integerValue withSuccess:success failure:failure];
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
        [self.cardVersionHandler verifyCode:code ofType:CodeTypePin1 withSuccess:success failure:failure];
    } else {
        [self.cardVersionHandler verifyCode:code ofType:CodeTypePin2 withSuccess:success failure:failure];
    }
}

- (NSNumber *)retryCountFromData:(NSData *)data {
    const unsigned char *dataBytes = [data bytes];
    for (int i = 0; i < [data length]; i++) {
        if (dataBytes[i] == 0x90) {
            if ([data length] > i + 1) {
                NSData *lengthData = [data subdataWithRange:NSMakeRange(i + 1, 1)];
                int length = [[lengthData toHexString] hexToInt];
                
                if ([data length] > i + 1 + length) {
                    NSData *counterData = [data subdataWithRange:NSMakeRange(i + 2, length)];
                    int countValue = [[counterData toHexString] hexToInt];
                    
                    return [NSNumber numberWithInt:countValue];
                }
            }
        }
    }
    
    return nil;
}

- (void)readCert:(CardAction)certAction success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    
    if (certAction == CardActionReadSigningCert) {
        [self.cardVersionHandler readSignatureCertificateWithSuccess:success failure:failure];
    } else if (certAction == CardActionReadAuthenticationCert) {
        [self.cardVersionHandler readAuthenticationCertificateWithSuccess:success failure:failure];
    }
    
}

- (void)finishCurrentAction {
    @synchronized (self) {
        if (self.isExecutingAction) {
            self.isExecutingAction = NO;
            [self.cardActions removeObject:self.cardActions.firstObject];
        }
        
        [self executeNextAction];
    }
}

- (BOOL)isReaderConnected {
    assert(self.cardReader != nil);
    return self.cardReader && [self.cardReader isConnected];
}

- (void)isCardInserted:(BoolBlock) completion {
    @synchronized (self) {
        CardActionObject *actionObject = [CardActionObject new];
        actionObject.boolBlock = completion;
        actionObject.cardAction = CardActionGetCardStatus;
        
        [self.cardActions addObject:actionObject];
        [self executeNextAction];
    }
}

#pragma mark - Reader setup
- (void)setupWithPeripheral:(CBPeripheral *)peripheral success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    CardReaderACR3901U_S1 *reader = [CardReaderACR3901U_S1 new];
    reader.delegate = self;
    [reader setupWithPeripheral:peripheral success:^(NSData *responseObject) {
        self.cardReader = reader;
        success(responseObject);
        
    } failure:^(NSError *error) {
        MLLog(@"Failed to set up peripheral: %@", [error localizedDescription]);
        failure(error);
    }];
}


#pragma mark - ReaderSelectionViewControllerDelegate

- (void)peripheralSelected:(CBPeripheral *)peripheral {
    [self setupWithPeripheral:peripheral success:^(NSData *data) {
        if (self.isExecutingAction) {
            [self executeAfterReaderCheck:[self.cardActions firstObject] abduLength:0];
        }
    } failure:^(NSError *error) {
        
        if (self.isExecutingAction) {
            CardActionObject *action = [self.cardActions firstObject];
            action.failureBlock(error);
            [self finishCurrentAction];
        }
    }];
}

- (void)cancelledReaderSelection {
    if (self.isExecutingAction) {
        [self clearActionsWithError:[MoppLibError readerSelectionCanceledError]];
    }
}

- (void)clearActionsWithError:(NSError *)error {
    self.isExecutingAction = NO;
    
    while (self.cardActions.count > 0) {
        CardActionObject *action = [self.cardActions firstObject];
        if (action.failureBlock) {
            action.failureBlock(error);
        } else if (action.boolBlock) {
            action.boolBlock(NO);
        }
        [self.cardActions removeObject:action];
    }
}

#pragma mark - CBManagerHelperDelegate

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationReaderStatusChanged object:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationReaderStatusChanged object:nil];
    
    //Making sure we don't get stuck with some action, that can't be completed anymore
    [self clearActionsWithError:[MoppLibError readerNotFoundError]];
}

#pragma mark - CardReaderWrapperDelegate

- (void)cardStatusUpdated:(CardStatus)status {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationReaderStatusChanged object:nil];
    
    if (status == CardStatusAbsent) {
        //Making sure we don't get stuck with some action, that can't be completed anymore
        [self.cardReader resetReader];
        [self clearActionsWithError:[MoppLibError cardNotFoundError]];
    }
}
@end


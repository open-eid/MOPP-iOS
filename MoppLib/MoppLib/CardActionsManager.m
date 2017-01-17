//
//  CardActionsManager.m
//  MoppLib
//
//  Created by Katrin Annuk on 23/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "CardActionsManager.h"
#import "CardReaderACR3901U_S1.h"
#import "ReaderSelectionViewController.h"
#import "MoppLibError.h"
#import "NSData+Additions.h"
#import "EstEIDv3_4.h"
#import "EstEIDv3_5.h"
#import "CBManagerHelper.h"
#import "MoppLibCertificate.h"

typedef NS_ENUM(NSUInteger, CardAction) {
  CardActionReadPublicData,
  CardActionChangePin,
  CardActionChangePinWithPuk,
  CardActionUnblockPin,
  CardActionPinRetryCount,
  CardActionReadSigningCert,
  CardActionReadAuthenticationCert,
  CardActionReadOwnerBirthDate
};

NSString *const kCardActionDataCodeType = @"Code type";
NSString *const kCardActionDataNewCode = @"New code";
NSString *const kCardActionDataVerify = @"Verify";

@interface CardActionObject : NSObject
@property (nonatomic, assign) NSUInteger cardAction;
@property (nonatomic, strong) void (^successBlock)(id);
@property (nonatomic, strong) FailureBlock failureBlock;
@property (nonatomic, strong) UIViewController *controller;
@property (nonatomic, strong) NSDictionary *data;
@end

@implementation CardActionObject

@end


@interface CardActionsManager() <ReaderSelectionViewControllerDelegate, CBManagerHelperDelegate, CardReaderWrapperDelegate>

@property (nonatomic, strong) id<CardReaderWrapper> cardReader;
@property (nonatomic, strong) NSMutableArray *cardActions;
@property (nonatomic, assign) BOOL isExecutingAction;
@property (nonatomic, strong) id<CardCommands> cardVersionHandler;


@end

@implementation CardActionsManager

static CardActionsManager *sharedInstance = nil;

+ (CardActionsManager *)sharedInstance {
  if (sharedInstance == nil) {
    sharedInstance = [CardActionsManager new];
    [[CBManagerHelper sharedInstance] addDelegate:sharedInstance];
  }
  return sharedInstance;
}

- (NSMutableArray *)cardActions {
  if (!_cardActions) {
    _cardActions = [NSMutableArray new];
  }
  
  return _cardActions;
}

- (void)setCardReader:(id<CardReaderWrapper>)cardReader {
  _cardReader = cardReader;
  [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationReaderStatusChanged object:nil];
}

- (void)cardPersonalDataWithViewController:(UIViewController *)controller success:(void (^)(NSData *))success failure:(void (^)(NSError *))failure {
  [self addCardAction:CardActionReadPublicData data:nil viewController:controller success:success failure:failure];
}

- (void)cardOwnerBirthDateWithViewController:(UIViewController *)controller success:(void(^)(NSDate *date))success failure:(void(^)(NSError *error))failure {
  [self addCardAction:CardActionReadOwnerBirthDate data:nil viewController:controller success:success failure:failure];

}

- (void)signingCertWithViewController:(UIViewController *)controller success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure {
  [self addCardAction:CardActionReadSigningCert data:nil viewController:controller success:success failure:failure];
}

- (void)authenticationCertWithViewController:(UIViewController *)controller success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure {
  [self addCardAction:CardActionReadAuthenticationCert data:nil viewController:controller success:success failure:failure];
}

- (void)changeCode:(CodeType)type withVerifyCode:(NSString *)verify to:(NSString *)newCode viewController:(UIViewController *)controller success:(void (^)(void))success failure:(void (^)(NSError *))failure {
  NSDictionary *data = @{kCardActionDataCodeType:[NSNumber numberWithInt:type], kCardActionDataVerify:verify, kCardActionDataNewCode:newCode};
  [self addCardAction:CardActionChangePin data:data viewController:controller success:^(id data) {
    success();
  } failure:failure];
}

- (void)changePin:(CodeType)type withPuk:(NSString *)puk to:(NSString *)newPin viewController:(UIViewController *)controller success:(void (^)(void))success failure:(void (^)(NSError *))failure {
  NSDictionary *data = @{kCardActionDataCodeType:[NSNumber numberWithInt:type], kCardActionDataVerify:puk, kCardActionDataNewCode:newPin};
  [self addCardAction:CardActionChangePinWithPuk data:data viewController:controller success:^(id data) {
    success();
  } failure:failure];
}

- (void)code:(CodeType)type retryCountWithViewController:(UIViewController *)controller success:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure {
  NSDictionary *data = @{kCardActionDataCodeType:[NSNumber numberWithInt:type]};
  [self addCardAction:CardActionPinRetryCount data:data viewController:controller success:success failure:failure];
}

- (void)unblockCode:(CodeType)type withPuk:(NSString *)puk newCode:(NSString *)newCode viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  NSDictionary *data = @{kCardActionDataCodeType:[NSNumber numberWithInt:type], kCardActionDataVerify:puk, kCardActionDataNewCode:newCode};
  [self addCardAction:CardActionUnblockPin data:data viewController:controller success:^(id data) {
    success();
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
- (void)addCardAction:(NSUInteger)action data:(NSDictionary *)data viewController:(UIViewController *)controller success:(void (^)(id))success failure:(void (^)(NSError *))failure {
  
  @synchronized (self) {
    CardActionObject *actionObject = [CardActionObject new];
    actionObject.successBlock = success;
    actionObject.failureBlock = ^(NSError *error) {
      [self notifyIdNeeded:error];
      failure(error);
    };
    actionObject.cardAction = action;
    actionObject.controller = controller;
    actionObject.data = data;
    
    [self.cardActions addObject:actionObject];
    [self executeNextAction];
  }
}

- (void)executeNextAction {
  @synchronized (self) {
    if (self.cardActions.count > 0 && !self.isExecutingAction) {
      self.isExecutingAction = YES;
      CardActionObject *action = self.cardActions.firstObject;
      [self executeAfterReaderCheck:action];
    }
  }
}

- (void)executeAfterReaderCheck:(CardActionObject *)action {
  if ([self isReaderConnected]) {
    [self.cardReader isCardInserted:^(BOOL isInserted) {
      if (isInserted) {
        
        [self.cardReader isCardPoweredOn:^(BOOL isPoweredOn) {
          if (isPoweredOn) {
            [self executeAction:action];
          } else {
            [self.cardReader powerOnCard:^(NSData *responseObject) {
              [self.cardReader transmitCommand:kCommandGetCardVersion success:^(NSData *responseObject) {
                NSData *trailerData = [responseObject responseTrailerData];
                const unsigned char *trailer = [trailerData bytes];
                
                if (trailer[0] == 0x90 && trailer[1] == 0x00) {
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
                    NSLog(@"Unsupported card version. Going to use v3.5 protocol");
                    EstEIDv3_5 *handler = [EstEIDv3_5 new];
                    [handler setReader:self.cardReader];
                    self.cardVersionHandler = handler;

                  }
                }
                
                [self executeAction:action];

              } failure:^(NSError *error) {
                NSLog(@"Unable to determine card version");
                action.failureBlock([MoppLibError cardVersionUnknownError]);
                [self finishCurrentAction];
              }];

            } failure:^(NSError *error) {
              NSLog(@"Unable to power on card");
              action.failureBlock([MoppLibError cardNotFoundError]);
              [self finishCurrentAction];
            }];
          }
        }];
        
      } else {
        NSLog(@"Card not inserted");
        action.failureBlock([MoppLibError cardNotFoundError]);
        [self finishCurrentAction];
      }
    }];
  } else {
    UINavigationController *navController = [[UIStoryboard storyboardWithName:@"ReaderSelection" bundle:[NSBundle bundleForClass:[ReaderSelectionViewController class]]] instantiateInitialViewController];
    ReaderSelectionViewController *viewController = [navController topViewController];
    viewController.delegate = self;
    [action.controller presentViewController:navController animated:YES completion:^{
      
    }];
  }
}

- (void)executeAction:(CardActionObject *)actionObject {
  if (!self.cardVersionHandler) {
    // Something went wrong with reader setup. Let's make another round
    self.cardReader = nil;
    [self executeAfterReaderCheck:actionObject];
    return;
  }
  
  void (^success)(id) = ^void (id response) {
    actionObject.successBlock(response);
    [self finishCurrentAction];
  };
  
  void (^failure)(id) = ^void (NSError *error) {
    actionObject.failureBlock(error);
    [self finishCurrentAction];
  };
  
  switch (actionObject.cardAction) {
    case CardActionReadPublicData: {
      [self.cardVersionHandler readPublicDataWithSuccess:success failure:failure];
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
      
    default:
      break;
  }
}

- (void) blockPin:(CodeType)pinId completion:(void (^)(void))completion {
  [self blockPin:pinId withCode:@"00000" completion:completion];
}

NSString *blockBackupCode = @"00001";
- (void)blockPin:(CodeType)pinId withCode:(NSString *)code completion:(void (^)(void))completion {
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

- (void)readCert:(CardAction)certAction success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure {
  
  void (^getUseCount)(NSData *) = ^void (NSData *data) {
    MoppLibCertData *certData = [MoppLibCertData new];
    [MoppLibCertificate certData:certData updateWithData:[data bytes] length:data.length];
    
    int record = 0;
    if (certAction == CardActionReadSigningCert) {
      record = 1;
    } else {
      record = 3;
    }
    [self.cardVersionHandler readSecretKeyRecord:record withSuccess:^(NSData *data) {
      NSData *keyUsageData = [data subdataWithRange:NSMakeRange(12, 3)];
      int counterStart = [@"FF FF FF" hexToInt];
      int counterValue = [[keyUsageData toHexString] hexToInt];
      certData.usageCount = counterStart - counterValue;
      
      success(certData);
    } failure:failure];
  };
  
  if (certAction == CardActionReadSigningCert) {
    [self.cardVersionHandler readSignatureCertificateWithSuccess:getUseCount failure:failure];
  } else if (certAction == CardActionReadAuthenticationCert) {
    [self.cardVersionHandler readAuthenticationCertificateWithSuccess:getUseCount failure:failure];
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
  return self.cardReader && [self.cardReader isConnected];
}

- (void)isCardInserted:(void(^)(BOOL)) completion {
  if (self.cardReader) {
    [self.cardReader isCardInserted:completion];
  } else {
    completion(NO);
  }
}

#pragma mark - Reader setup
- (void)setupWithPeripheral:(CBPeripheral *)peripheral success:(void (^)(NSData *))success failure:(void (^)(NSError *))failure {
  CardReaderACR3901U_S1 *reader = [CardReaderACR3901U_S1 new];
  reader.delegate = self;
  [reader setupWithPeripheral:peripheral success:^(NSData *responseObject) {
    self.cardReader = reader;
    success(responseObject);
    
  } failure:^(NSError *error) {
    NSLog(@"Failed to set up peripheral: %@", [error localizedDescription]);
    failure(error);
  }];
}


#pragma mark - ReaderSelectionViewControllerDelegate

- (void)peripheralSelected:(CBPeripheral *)peripheral {
  [self setupWithPeripheral:peripheral success:^(NSData *data) {
    if (self.isExecutingAction) {
      [self executeAfterReaderCheck:[self.cardActions firstObject]];
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
    CardActionObject *action = [self.cardActions firstObject];
    action.failureBlock([MoppLibError readerNotFoundError]);
    
    [self clearActions];
  }
}

- (void)clearActions {
  self.isExecutingAction = NO;
  [self.cardActions removeAllObjects];
}

#pragma mark - CBManagerHelperDelegate

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationReaderStatusChanged object:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationReaderStatusChanged object:nil];
  
  //Making sure we don't get stuck with some action, that can't be completed anymore
  [self clearActions];
}

#pragma mark - CardReaderWrapperDelegate

- (void)cardStatusUpdated:(CardStatus)status {
  [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationReaderStatusChanged object:nil];
  
  if (status == CardStatusAbsent) {
    //Making sure we don't get stuck with some action, that can't be completed anymore
    [self.cardReader resetReader];
    [self clearActions];
  }
}
@end


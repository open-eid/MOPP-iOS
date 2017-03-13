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
  CardActionVerifyCode,
  CardActionCalculateSignature
};

NSString *const kCardActionDataHash = @"Hash";
NSString *const kCardActionDataCodeType = @"Code type";
NSString *const kCardActionDataNewCode = @"New code";
NSString *const kCardActionDataVerify = @"Verify";
NSString *const kCardActionDataRecord = @"Record";

@interface CardActionObject : NSObject
@property (nonatomic, assign) CardAction cardAction;
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

- (void)minimalCardPersonalDataWithViewController:(UIViewController *)controller success:(PersonalDataBlock)success failure:(FailureBlock)failure {
  [self addCardAction:CardActionReadMinPublicData data:nil viewController:controller success:success failure:failure];
}

- (void)cardPersonalDataWithViewController:(UIViewController *)controller success:(PersonalDataBlock)success failure:(FailureBlock)failure {
  [self addCardAction:CardActionReadPublicData data:nil viewController:controller success:success failure:failure];
}

- (void)cardOwnerBirthDateWithViewController:(UIViewController *)controller success:(void(^)(NSDate *date))success failure:(FailureBlock)failure {
  [self addCardAction:CardActionReadOwnerBirthDate data:nil viewController:controller success:success failure:failure];

}

- (void)certUsageCountForRecord:(int)record controller:(UIViewController *)controller success:(void(^)(int))success failure:(FailureBlock)failure {

  NSDictionary *data = @{kCardActionDataRecord:[NSNumber numberWithInt:record]};
  [self addCardAction:CardActionReadSecretKey data:data viewController:controller success:^(NSData *data) {
    NSData *keyUsageData = [data subdataWithRange:NSMakeRange(12, 3)];
    int counterStart = [@"FF FF FF" hexToInt];
    int counterValue = [[keyUsageData toHexString] hexToInt];
    success(counterStart - counterValue);
  } failure:failure];
}

- (void)signingCertWithViewController:(UIViewController *)controller success:(CertDataBlock)success failure:(FailureBlock)failure {
  
  MoppLibCertData *certData = [MoppLibCertData new];

  [self signingCertDataWithViewController:controller success:^(NSData *data) {
    [MoppLibCertificate certData:certData updateWithData:[data bytes] length:data.length];
  } failure:failure];
  
  [self certUsageCountForRecord:1 controller:controller success:^(int usageCount) {
    certData.usageCount = usageCount;
    
    success(certData);
  } failure:failure];
}

- (void)signingCertDataWithViewController:(UIViewController *)controller success:(DataSuccessBlock)success failure:(FailureBlock)failure {
  [self addCardAction:CardActionReadSigningCert data:nil viewController:controller success:success failure:failure];
}

- (void)authenticationCertWithViewController:(UIViewController *)controller success:(CertDataBlock)success failure:(FailureBlock)failure {
  MoppLibCertData *certData = [MoppLibCertData new];

  [self authenticationCertDataWithViewController:controller success:^(NSData *data) {
    [MoppLibCertificate certData:certData updateWithData:[data bytes] length:data.length];
  } failure:failure];
  
  [self certUsageCountForRecord:3 controller:controller success:^(int usageCount) {
    certData.usageCount = usageCount;
    
    success(certData);
  } failure:failure];
}

- (void)authenticationCertDataWithViewController:(UIViewController *)controller success:(DataSuccessBlock)success failure:(FailureBlock)failure {
  [self addCardAction:CardActionReadAuthenticationCert data:nil viewController:controller success:success failure:failure];
}

- (void)changeCode:(CodeType)type withVerifyCode:(NSString *)verify to:(NSString *)newCode viewController:(UIViewController *)controller success:(VoidBlock)success failure:(FailureBlock)failure {
  NSDictionary *data = @{kCardActionDataCodeType:[NSNumber numberWithInt:type], kCardActionDataVerify:verify, kCardActionDataNewCode:newCode};
  [self addCardAction:CardActionChangePin data:data viewController:controller success:^(id data) {
    success();
  } failure:failure];
}

- (void)changePin:(CodeType)type withPuk:(NSString *)puk to:(NSString *)newPin viewController:(UIViewController *)controller success:(VoidBlock)success failure:(FailureBlock)failure {
  NSDictionary *data = @{kCardActionDataCodeType:[NSNumber numberWithInt:type], kCardActionDataVerify:puk, kCardActionDataNewCode:newPin};
  [self addCardAction:CardActionChangePinWithPuk data:data viewController:controller success:^(id data) {
    success();
  } failure:failure];
}

- (void)code:(CodeType)type retryCountWithViewController:(UIViewController *)controller success:(void (^)(NSNumber *))success failure:(FailureBlock)failure {
  NSDictionary *data = @{kCardActionDataCodeType:[NSNumber numberWithInt:type]};
  [self addCardAction:CardActionPinRetryCount data:data viewController:controller success:success failure:failure];
}

- (void)unblockCode:(CodeType)type withPuk:(NSString *)puk newCode:(NSString *)newCode viewController:(UIViewController *)controller success:(VoidBlock)success failure:(FailureBlock)failure {
  NSDictionary *data = @{kCardActionDataCodeType:[NSNumber numberWithInt:type], kCardActionDataVerify:puk, kCardActionDataNewCode:newCode};
  [self addCardAction:CardActionUnblockPin data:data viewController:controller success:^(id data) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationRetryCounterChanged object:nil];
    success();
  } failure:failure];
}

- (void)calculateSignatureFor:(NSData *)hash pin2:(NSString *)pin2 controller:(UIViewController *)controller success:(DataSuccessBlock)success failure:(FailureBlock)failure {
  NSDictionary *data = @{kCardActionDataHash:hash, kCardActionDataVerify:pin2};
  [self addCardAction:CardActionCalculateSignature data:data viewController:controller success:success failure:failure];
}

- (void)addSignature:(MoppLibContainer *)moppContainer controller:(UIViewController *)controller success:(void(^)(MoppLibContainer *container, BOOL signatureWasAdded))success failure:(FailureBlock)failure {
  
  [self code:CodeTypePin2 retryCountWithViewController:controller success:^(NSNumber *count) {
    if (count.intValue > 0) {
      NSDictionary *data = @{kCardActionDataCodeType:[NSNumber numberWithInt:CodeTypePin2]};
      
      [self addCardAction:CardActionVerifyCode data:data viewController:controller success:^(NSString *pin2) {
        [self addSignatureTo:moppContainer controller:controller pin2:pin2 success:success andFailure:failure];
        
      } failure:^(NSError *error) {
        if (error.code == moppLibErrorWrongPin) {
          int retryCount = [[error.userInfo objectForKey:kMoppLibUserInfoRetryCount] intValue];
          
          if (retryCount == 0) {
            failure([MoppLibError pinBlockedError]);
          } else {
            [self displayInvalidPinError:error on:controller forPin:CodeTypePin2 completion:^{
              // Repeat until user enters correct PIN, cancels or PIN gets blocked
              [self addSignature:moppContainer controller:controller success:success failure:failure];
            }];
          }
        } else {
          failure(error);
        }
      }];
    } else {
      failure([MoppLibError pinBlockedError]);
    }
  } failure:failure];
}

- (void)addSignatureTo:(MoppLibContainer *)moppContainer controller:(UIViewController *)controller pin2:(NSString *)pin2 success:(void(^)(MoppLibContainer *container, BOOL signatureWasAdded))success andFailure:(FailureBlock)failure {
  [self signingCertDataWithViewController:controller success:^(NSData *certData) {
    
    if ([[MoppLibDigidocManager sharedInstance] container:moppContainer containsSignatureWithCert:certData]) {
      NSString *title = MLLocalizedString(@"signature-already-exists-title", nil);
      NSString *message = MLLocalizedString(@"signature-already-exists-message", nil);
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:MLLocalizedString(@"action-yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[MoppLibDigidocManager sharedInstance] addSignature:moppContainer pin2:pin2 cert:certData success:^(MoppLibContainer *container) {
          success(container, YES);
        } andFailure:failure];
      }]];
      
      [alert addAction:[UIAlertAction actionWithTitle:MLLocalizedString(@"action-no", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        success(moppContainer, NO);
      }]];
      [controller presentViewController:alert animated:YES completion:nil];
      
    } else {
      [[MoppLibDigidocManager sharedInstance] addSignature:moppContainer pin2:pin2 cert:certData success:^(MoppLibContainer *container) {
        success(container, YES);
      } andFailure:failure];
    }
  } failure:failure];
}

- (void)displayInvalidPinError:(NSError *)error on:(UIViewController *)controller forPin:(CodeType)type completion:(void (^)(void))completion {
  NSString *pinString = [self pinStringForCode:type];
  NSString *message;
  
  BOOL dismissViewcontroller = NO;
  int retryCount = [[error.userInfo objectForKey:kMoppLibUserInfoRetryCount] intValue];

  message = [NSString stringWithFormat:MLLocalizedString(@"pin-actions-wrong-pin-retry", nil), pinString, retryCount];

  UIAlertController *alert = [UIAlertController alertControllerWithTitle:MLLocalizedString(@"Error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:MLLocalizedString(@"action-ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    completion();
  }]];
  [controller presentViewController:alert animated:YES completion:nil];
}

- (void)notifyIdNeeded:(NSError *)error {
  if (error.code == moppLibErrorWrongPin) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationRetryCounterChanged object:nil];
  }
}

- (NSString *)pinStringForCode:(CodeType)type {
  if (type == CodeTypePin1) {
    return MLLocalizedString(@"pin-actions-pin1", nil);
    
  } else if (type == CodeTypePin2) {
    return MLLocalizedString(@"pin-actions-pin2", nil);
    
  }else if (type == CodeTypePuk) {
    return MLLocalizedString(@"pin-actions-puk", nil);
  }
  return @"";
}

/**
 * Adds card action to queue. One card action may require sending multiple commands to id card. These commands often must be executed in specific order. For that reason we must make sure commands from different card actions are not mixed.
 *
 * @param action    card action to be added to execution queue
 * @param success   block to be called when card action is completed successfully
 * @param failure   block to be called when executing card action fails
 */
- (void)addCardAction:(NSUInteger)action data:(NSDictionary *)data viewController:(UIViewController *)controller success:(void (^)(id))success failure:(FailureBlock)failure {
  
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
                    MLLog(@"Unsupported card version. Going to use v3.5 protocol");
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
          }
        }];
        
      } else {
        MLLog(@"Card not inserted");
        action.failureBlock([MoppLibError cardNotFoundError]);
        [self finishCurrentAction];
      }
    }];
  } else {
    UINavigationController *navController = [[UIStoryboard storyboardWithName:@"ReaderSelection" bundle:[NSBundle bundleForClass:[ReaderSelectionViewController class]]] instantiateInitialViewController];
    ReaderSelectionViewController *viewController = (ReaderSelectionViewController *)[navController topViewController];
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
    
    case CardActionVerifyCode: {
      CodeType type = ((NSNumber *)[actionObject.data objectForKey:kCardActionDataCodeType]).integerValue;
      NSString *verifyCode = [actionObject.data objectForKey:kCardActionDataVerify];
      if (!verifyCode) {
        NSString *title = [self pinStringForCode:type];
        NSString *message;
        if (type == CodeTypePin1) {
          message = MLLocalizedString(@"container-details-enter-pin1", nil);
          
        } else if (type == CodeTypePin2) {
          message = MLLocalizedString(@"container-details-enter-pin2", nil);

        } else if (type == CodeTypePuk) {
          message = MLLocalizedString(@"container-details-enter-puk", nil);
        }
        NSString *placeholder = title;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
          textField.keyboardType = UIKeyboardTypeNumberPad;
          textField.placeholder = placeholder;
          textField.secureTextEntry = YES;
        }];
        NSString *ok = MLLocalizedString(@"action-ok", nil);
        NSString *cancel = MLLocalizedString(@"action-cancel", nil);

        [alert addAction:[UIAlertAction actionWithTitle:ok style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          NSString *pin = [alert.textFields[0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
          NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:actionObject.data];
          [dict setObject:pin forKey:kCardActionDataVerify];
          actionObject.data = dict;
          [self executeAction:actionObject]; // New round
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
          failure([MoppLibError pinNotProvidedError]);
        }]];
        
        [actionObject.controller presentViewController:alert animated:YES completion:nil];

        
      } else {
        [self.cardVersionHandler verifyCode:verifyCode ofType:type withSuccess:^(NSData *responseData) {
          success(verifyCode);
        } failure:failure];
      }
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
      [self.cardVersionHandler calculateSignatureFor:hash withPin2:pin2 success:success failure:failure];
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
    [self clearActionsWithError:[MoppLibError readerNotFoundError]];
  }
}

- (void)clearActionsWithError:(NSError *)error {
  self.isExecutingAction = NO;
  
  while (self.cardActions.count > 0) {
    CardActionObject *action = [self.cardActions firstObject];
    action.failureBlock([MoppLibError readerNotFoundError]);
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


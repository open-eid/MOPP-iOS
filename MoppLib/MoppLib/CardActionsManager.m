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
  CardActionChangePin1,
  CardActionChangePin2,
  CardActionUnblockPin1,
  CardActionUnblockPin2,
  CardActionReadSigningCert,
  CardActionReadAuthenticationCert
};



@interface CardActionObject : NSObject
@property (nonatomic, assign) NSUInteger cardAction;
@property (nonatomic, strong) void (^successBlock)(id);
@property (nonatomic, strong) FailureBlock failureBlock;
@property (nonatomic, strong) UIViewController *controller;
@end

@implementation CardActionObject


@end


@interface CardActionsManager() <ReaderSelectionViewControllerDelegate, CBManagerHelperDelegate>

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
  [self addCardAction:CardActionReadPublicData viewController:controller success:success failure:failure];
}

- (void)signingCertWithViewController:(UIViewController *)controller success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure {
  [self addCardAction:CardActionReadSigningCert viewController:controller success:success failure:failure];
}

- (void)authenticationCertWithViewController:(UIViewController *)controller success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure {
  [self addCardAction:CardActionReadAuthenticationCert viewController:controller success:success failure:failure];
}

/**
 * Adds card action to queue. One card action may require sending multiple commands to id card. These commands often must be executed in specific order. For that reason we must make sure commands from different card actions are not mixed.
 *
 * @param action    card action to be added to execution queue
 * @param success   block to be called when card action is completed successfully
 * @param failure   block to be called when executing card action fails
 */
- (void)addCardAction:(NSUInteger)action viewController:(UIViewController *)controller success:(void (^)(id))success failure:(void (^)(NSError *))failure {
  
  @synchronized (self) {
    CardActionObject *actionObject = [CardActionObject new];
    actionObject.successBlock = success;
    actionObject.failureBlock = failure;
    actionObject.cardAction = action;
    actionObject.controller = controller;
    
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
                
                const unsigned char *trailer = [responseObject responseTrailer];
                
                if (trailer[0] == 0x90 && trailer[1] == 0x00) {
                  const unsigned char *responseBytes = [responseObject bytes];

                  if (responseBytes[0] == 0x03 && responseBytes[1] == 0x05) {
                    self.cardVersionHandler = [EstEIDv3_5 new];
                  
                  } else if (responseBytes[0] == 0x03 && responseBytes[1] == 0x04) {
                    self.cardVersionHandler = [EstEIDv3_4 new];
                  
                  } else {
                    NSLog(@"Unsupported card version. Going to use v3.5 protocol");
                    self.cardVersionHandler = [EstEIDv3_5 new];

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
  switch (actionObject.cardAction) {
    case CardActionReadPublicData: {
      
      [self.cardVersionHandler cardReader:self.cardReader readPublicDataWithSuccess:^(MoppLibPersonalData *personalData) {
        actionObject.successBlock(personalData);
        [self finishCurrentAction];
        
      } failure:^(NSError *error) {
        actionObject.failureBlock(error);
        [self finishCurrentAction];
      }];
      break;
    }
      
    case CardActionChangePin1:
      break;
    
    case CardActionChangePin2:
      break;
    
    case CardActionUnblockPin1:
      break;
    
    case CardActionUnblockPin2:
      break;
      
    case CardActionReadSigningCert: {
      [self readCert:CardActionReadSigningCert success:actionObject.successBlock failure:actionObject.failureBlock];
      break;
    }
    case CardActionReadAuthenticationCert: {
      
      [self readCert:CardActionReadAuthenticationCert success:actionObject.successBlock failure:actionObject.failureBlock];
      break;
    }
      
    default:
      break;
  }
}

- (void)readCert:(CardAction)certAction success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure {
  
  void (^failedAction)(NSError *) = ^void (NSError *error) {
    failure(error);
    [self finishCurrentAction];
  };
  
  void (^getUseCount)(NSData *) = ^void (NSData *data) {
    MoppLibCertData *certData = [MoppLibCertData new];
    [MoppLibCertificate certData:certData updateWithData:[data bytes] length:data.length];
    
    int record = 0;
    if (certAction == CardActionReadSigningCert) {
      record = 1;
    } else {
      record = 3;
    }
    [self.cardVersionHandler cardReader:self.cardReader readSecretKeyRecord:record withSuccess:^(NSData *data) {
      NSData *keyUsageData = [data subdataWithRange:NSMakeRange(12, 3)];
      int counterStart = [@"FF FF FF" hexToInt];
      int counterValue = [[keyUsageData toHexString] hexToInt];
      certData.usageCount = counterStart - counterValue;
      
      success(certData);
      [self finishCurrentAction];
      
    } failure:failedAction];
  };
  
  if (certAction == CardActionReadSigningCert) {
    [self.cardVersionHandler cardReader:self.cardReader readSignatureCertificateWithSuccess:getUseCount failure:failedAction];
  } else if (certAction == CardActionReadAuthenticationCert) {
    [self.cardVersionHandler cardReader:self.cardReader readAuthenticationCertificateWithSuccess:getUseCount failure:failedAction];
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
    
    // TODO maybe we should cancel all actions in queue?
    [self finishCurrentAction];
  }
}

#pragma mark - CBManagerHelperDelegate

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationReaderStatusChanged object:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  [[NSNotificationCenter defaultCenter] postNotificationName:kMoppLibNotificationReaderStatusChanged object:nil];
}
@end


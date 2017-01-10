//
//  CardActionsManager.h
//  MoppLib
//
//  Created by Katrin Annuk on 23/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CardCommands.h"
#import "MoppLibCertData.h"

@interface CardActionsManager : NSObject
+ (CardActionsManager *)sharedInstance;

- (void)cardPersonalDataWithViewController:(UIViewController *)controller success:(void(^)(MoppLibPersonalData *))success failure:(void(^)(NSError *))failure;
- (void)signingCertWithViewController:(UIViewController *)controller success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure;
- (void)authenticationCertWithViewController:(UIViewController *)controller success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure;

- (void)changePin1WithViewController:(UIViewController *)controller newPin:(NSString *)newPin verifyCode:(NSString *)verify success:(void (^)(void))success failure:(void (^)(NSError *))failure;
- (void)changePin2WithViewController:(UIViewController *)controller newPin:(NSString *)newPin verifyCode:(NSString *)verify success:(void (^)(void))success failure:(void (^)(NSError *))failure;

- (void)pin1RetryCountWithViewController:(UIViewController *)controller success:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure;
- (void)pin2RetryCountWithViewController:(UIViewController *)controller success:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure;

- (void)isCardInserted:(void(^)(BOOL)) completion;
- (BOOL)isReaderConnected;
@end

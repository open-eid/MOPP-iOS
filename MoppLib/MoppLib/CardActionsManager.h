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
- (void)personalIdCodeWithViewController:(UIViewController *)controller success:(void(^)(NSString *idCode))success failure:(void(^)(NSError *))failure;
- (void)signingCertWithViewController:(UIViewController *)controller success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure;
- (void)authenticationCertWithViewController:(UIViewController *)controller success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure;

- (void)changePin1WithViewController:(UIViewController *)controller newPin:(NSString *)newPin puk:(NSString *)verify success:(void (^)(void))success failure:(void (^)(NSError *))failure;
- (void)changePin2WithViewController:(UIViewController *)controller newPin:(NSString *)newPin puk:(NSString *)verify success:(void (^)(void))success failure:(void (^)(NSError *))failure;

- (void)changePin1WithViewController:(UIViewController *)controller newPin:(NSString *)newPin oldPin:(NSString *)verify success:(void (^)(void))success failure:(void (^)(NSError *))failure;
- (void)changePin2WithViewController:(UIViewController *)controller newPin:(NSString *)newPin oldPin:(NSString *)verify success:(void (^)(void))success failure:(void (^)(NSError *))failure;


- (void)unblockPin1WithPuk:(NSString *)puk newPin1:(NSString *)newPin1 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure;
- (void)unblockPin2WithPuk:(NSString *)puk newPin2:(NSString *)newPin2 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure;

- (void)pin1RetryCountWithViewController:(UIViewController *)controller success:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure;
- (void)pin2RetryCountWithViewController:(UIViewController *)controller success:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure;

- (void)isCardInserted:(void(^)(BOOL)) completion;
- (BOOL)isReaderConnected;
@end

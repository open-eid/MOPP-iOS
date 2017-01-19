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

- (void)testMethod;

  
- (void)cardPersonalDataWithViewController:(UIViewController *)controller success:(void(^)(MoppLibPersonalData *))success failure:(void(^)(NSError *))failure;

- (void)cardOwnerBirthDateWithViewController:(UIViewController *)controller success:(void(^)(NSDate *date))success failure:(void(^)(NSError *error))failure;

- (void)signingCertWithViewController:(UIViewController *)controller success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure;
- (void)authenticationCertWithViewController:(UIViewController *)controller success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure;

- (void)changePin:(CodeType)type withPuk:(NSString *)puk to:(NSString *)newPin viewController:(UIViewController *)controller success:(void (^)(void))success failure:(void (^)(NSError *))failure;

- (void)changeCode:(CodeType)type withVerifyCode:(NSString *)verify to:(NSString *)newCode viewController:(UIViewController *)controller success:(void (^)(void))success failure:(void (^)(NSError *))failure;

- (void)unblockCode:(CodeType)type withPuk:(NSString *)puk newCode:(NSString *)newCode viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure ;

- (void)code:(CodeType)type retryCountWithViewController:(UIViewController *)controller success:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure;

- (void)isCardInserted:(void(^)(BOOL)) completion;
- (BOOL)isReaderConnected;
@end

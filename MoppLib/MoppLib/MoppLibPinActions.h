//
//  MoppLibPinActions.h
//  MoppLib
//
//  Created by Katrin Annuk on 09/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MoppLibPinActions : NSObject

+ (void)changePin1To:(NSString *)newPin1 withOldPin1:(NSString *)oldPin1 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure;
+ (void)changePin1To:(NSString *)newPin1 withPuk:(NSString *)puk viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure;
+ (void)changePin2To:(NSString *)newPin2 withOldPin2:(NSString *)oldPin2 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure;
+ (void)changePin2To:(NSString *)newPin2 withPuk:(NSString *)puk viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure;

+ (void)unblockPin1WithPuk:(NSString *)puk newPin1:(NSString *)newPin1 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure;
+ (void)unblockPin2WithPuk:(NSString *)puk newPin2:(NSString *)newPin2 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure;

@end

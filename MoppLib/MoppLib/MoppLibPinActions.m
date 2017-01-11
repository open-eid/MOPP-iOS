//
//  MoppLibPinActions.m
//  MoppLib
//
//  Created by Katrin Annuk on 09/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "MoppLibPinActions.h"
#import "CardActionsManager.h"

@implementation MoppLibPinActions

+ (void)changePin1To:(NSNumber *)newPin1 withOldPin1:(NSNumber *)oldPin1 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  [[CardActionsManager sharedInstance] changePin1WithViewController:controller newPin:newPin1 verifyCode:oldPin1 success:success failure:failure];
}

+ (void)changePin1To:(NSNumber *)newPin1 withPuk:(NSNumber *)puk viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  [[CardActionsManager sharedInstance] changePin1WithViewController:controller newPin:newPin1 verifyCode:puk success:success failure:failure];
}

+ (void)changePin2To:(NSNumber *)newPin2 withOldPin2:(NSNumber *)oldPin2 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  [[CardActionsManager sharedInstance] changePin2WithViewController:controller newPin:newPin2 verifyCode:oldPin2 success:success failure:failure];
}

+ (void)changePin2To:(NSNumber *)newPin2 withPuk:(NSNumber *)puk viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  [[CardActionsManager sharedInstance] changePin2WithViewController:controller newPin:newPin2 verifyCode:puk success:success failure:failure];
}

@end

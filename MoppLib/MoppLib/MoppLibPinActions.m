//
//  MoppLibPinActions.m
//  MoppLib
//
//  Created by Katrin Annuk on 09/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "MoppLibPinActions.h"
#import "CardActionsManager.h"
#import "MoppLibError.h"

@implementation MoppLibPinActions

+ (void)changePin1To:(NSString *)newPin1 withOldPin1:(NSString *)oldPin1 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  NSError *error = [self verifyPin1:newPin1 andVerificationCode:oldPin1];
  if (error) {
    failure(error);
  } else {
    [[CardActionsManager sharedInstance] changePin1WithViewController:controller newPin:newPin1 verifyCode:oldPin1 success:success failure:failure];
  }
}

+ (void)changePin1To:(NSNumber *)newPin1 withPuk:(NSNumber *)puk viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  NSError *error = [self verifyPin1:newPin1 andVerificationCode:puk];
  if (error) {
    failure(error);
  } else {
    [[CardActionsManager sharedInstance] changePin1WithViewController:controller newPin:newPin1 verifyCode:puk success:success failure:failure];
  }
}

+ (void)changePin2To:(NSNumber *)newPin2 withOldPin2:(NSNumber *)oldPin2 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  NSError *error = [self verifyPin2:newPin2 andVerificationCode:oldPin2];
  if (error) {
    failure(error);
  } else {
    [[CardActionsManager sharedInstance] changePin2WithViewController:controller newPin:newPin2 verifyCode:oldPin2 success:success failure:failure];
  }
}

+ (void)changePin2To:(NSNumber *)newPin2 withPuk:(NSNumber *)puk viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  NSError *error = [self verifyPin2:newPin2 andVerificationCode:puk];
  if (error) {
    failure(error);
  } else {
    [[CardActionsManager sharedInstance] changePin2WithViewController:controller newPin:newPin2 verifyCode:puk success:success failure:failure];
  }
}

+ (void)unblockPin1WithPuk:(NSString *)puk newPin1:(NSString *)newPin1 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  NSError *error = [self verifyPin1:newPin1 andVerificationCode:puk];
  if (error) {
    failure(error);
  } else {
    [[CardActionsManager sharedInstance] unblockPin1WithPuk:puk newPin1:newPin1 viewController:controller success:success failure:failure];
  }
}

+ (void)unblockPin2WithPuk:(NSString *)puk newPin2:(NSString *)newPin2 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  NSError *error = [self verifyPin2:newPin2 andVerificationCode:puk];
  if (error) {
    failure(error);
  } else {
    [[CardActionsManager sharedInstance] unblockPin2WithPuk:puk newPin2:newPin2 viewController:controller success:success failure:failure];
  }
}

+ (NSError *)verifyPin1:(NSString *)pin1 andVerificationCode:(NSString *)verificationCode {
  if ([pin1 isEqualToString:verificationCode]) {
    return [MoppLibError pinMatchesVerificationCodeError];
  
  } else if (pin1.length < 4 || pin1.length > 12) {
    return [MoppLibError incorrectPinLengthError];
  }
  
  return nil;
}

+ (NSError *)verifyPin2:(NSString *)pin2 andVerificationCode:(NSString *)verificationCode {
  if ([pin2 isEqualToString:verificationCode]) {
    return [MoppLibError pinMatchesVerificationCodeError];
    
  } else if (pin2.length < 5 || pin2.length > 12) {
    return [MoppLibError incorrectPinLengthError];
  }
  
  return nil;
}

@end

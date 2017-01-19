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
  [self verifyType:CodeTypePin1 pin:newPin1 andVerificationCode:oldPin1 viewController:controller success:^{
    [[CardActionsManager sharedInstance] changeCode:CodeTypePin1 withVerifyCode:oldPin1 to:newPin1 viewController:controller success:success failure:failure];
  } failure:failure];
}

+ (void)changePin1To:(NSString *)newPin1 withPuk:(NSString *)puk viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  [self verifyType:CodeTypePin1 pin:newPin1 andVerificationCode:puk viewController:controller success:^{
    [[CardActionsManager sharedInstance] changePin:CodeTypePin1 withPuk:puk to:newPin1 viewController:controller success:success failure:failure];
  } failure:failure];
}

+ (void)changePin2To:(NSString *)newPin2 withOldPin2:(NSString *)oldPin2 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  [self verifyType:CodeTypePin2 pin:newPin2 andVerificationCode:oldPin2 viewController:controller success:^{
    [[CardActionsManager sharedInstance] changeCode:CodeTypePin2 withVerifyCode:oldPin2 to:newPin2 viewController:controller success:success failure:failure];
  } failure:failure];
}

+ (void)changePin2To:(NSString *)newPin2 withPuk:(NSString *)puk viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  [self verifyType:CodeTypePin2 pin:newPin2 andVerificationCode:puk viewController:controller success:^{
    [[CardActionsManager sharedInstance] changePin:CodeTypePin2 withPuk:puk to:newPin2 viewController:controller success:success failure:failure];
  } failure:failure];
}

+ (void)unblockPin1WithPuk:(NSString *)puk newPin1:(NSString *)newPin1 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  [self verifyType:CodeTypePin1 pin:newPin1 andVerificationCode:puk viewController:controller success:^{
    [[CardActionsManager sharedInstance] unblockCode:CodeTypePin1 withPuk:puk newCode:newPin1 viewController:controller success:success failure:failure];
  } failure:failure];
}

+ (void)unblockPin2WithPuk:(NSString *)puk newPin2:(NSString *)newPin2 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
  [self verifyType:CodeTypePin2 pin:newPin2 andVerificationCode:puk viewController:controller success:^{
    [[CardActionsManager sharedInstance] unblockCode:CodeTypePin2 withPuk:puk newCode:newPin2 viewController:controller success:success failure:failure];
  } failure:failure];
}

+ (void)verifyType:(CodeType)type pin:(NSString *)pin andVerificationCode:(NSString *)verificationCode viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure {
    if ([pin isEqualToString:verificationCode]) {
      failure([MoppLibError pinMatchesVerificationCodeError]);
      
    } else if (type == CodeTypePin1 && (pin.length < [self pin1MinLength] || pin.length > [self pin1MaxLength])) {
      failure([MoppLibError incorrectPinLengthError]);
      
    } else if (type == CodeTypePin2 && (pin.length < [self pin2MinLength] || pin.length > [self pin2MaxLength])) {
      failure([MoppLibError incorrectPinLengthError]);
      
    } else {
      NSCharacterSet* notDigits = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
      if ([pin rangeOfCharacterFromSet:notDigits].location == NSNotFound)
      {
        // newString consists only of the digits 0 through 9

        // Checking strings that new pin shouldn't match
        NSArray *forbiddenPins = type == CodeTypePin1 ? [self forbiddenPin1s] : [self forbiddenPin2s];
        for (NSString *forbiddenPin in forbiddenPins) {
          if ([pin isEqualToString:forbiddenPin]) {
            failure([MoppLibError tooEasyPinError]);
            return;
          }
        }
        
        // Checking strings that new pin shouldn't contain
        [self forbiddenPinPartsForCode:type viewController:controller completion:^(NSArray *forbiddenPins) {
          for (NSString *forbiddenPin in forbiddenPins) {
            if ([pin containsString:forbiddenPin]) {
              failure([MoppLibError tooEasyPinError]);
              return;
            }
          }
          success();
        }];
      } else {
        failure([MoppLibError pinContainsInvalidCharactersError]);
      }
    }
}

+ (void)forbiddenPinPartsForCode:(CodeType)type viewController:(UIViewController *)controller completion:(void(^)(NSArray *))complete {
  [[CardActionsManager sharedInstance] cardOwnerBirthDateWithViewController:controller success:^(NSDate *date) {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY"];
    NSString *code = [formatter stringFromDate:date];
    [array addObject:code];
    
    [formatter setDateFormat:@"ddMM"];
    NSString *code2 = [formatter stringFromDate:date];
    [array addObject:code2];
    
    [formatter setDateFormat:@"MMdd"];
    NSString *code3 = [formatter stringFromDate:date];
    [array addObject:code3];
    
    complete(array);
    
  } failure:^(NSError *error) {
    complete(nil);
  }];
}

+ (NSArray *)forbiddenPin1s {
  return @[@"0000", @"1234"];
};

+ (NSArray *)forbiddenPin2s {
  return @[@"00000", @"12345"];
};

+ (int)pin1MinLength {
  return 4;
}

+ (int)pin2MinLength {
  return 5;
}

+ (int)pin1MaxLength {
  return 12;
}

+ (int)pin2MaxLength {
  return 12;
}

@end

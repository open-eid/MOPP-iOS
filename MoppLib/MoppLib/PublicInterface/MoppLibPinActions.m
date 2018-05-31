//
//  MoppLibPinActions.m
//  MoppLib
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#import "MoppLibPinActions.h"
#import "CardActionsManager.h"
#import "MoppLibError.h"
#import "MoppLibPrivateConstants.h"

@implementation MoppLibPinActions

+ (void)changePukTo:(NSString *)newPuk withOldPuk:(NSString *)oldPuk success:(VoidBlock)success failure:(FailureBlock)failure {
  
  if (![self canDoPinModifications]) {
    failure([MoppLibError restrictedAPIError]);
    return;
  }
  
  // PUK change command gives unusual error in case of incorrect length. Checking these requirements here instead.
  if (newPuk.length < [self pukMinLength] || newPuk.length > [self pukMaxLength]) {
    failure([MoppLibError incorrectPinLengthError]);
    return;
  }
  
  for (NSString *puk in [self forbiddenPuks]) {
    if ([puk isEqualToString:newPuk]) {
      failure([MoppLibError invalidPinError]);
      return;
    }
  }
  
  [self verifyType:CodeTypePuk pin:newPuk andVerificationCode:oldPuk success:^{
    [[CardActionsManager sharedInstance] changeCode:CodeTypePuk withVerifyCode:oldPuk to:newPuk success:success failure:failure];
  } failure:failure];
}

+ (void)changePin1To:(NSString *)newPin1 withOldPin1:(NSString *)oldPin1 success:(VoidBlock)success failure:(FailureBlock)failure {
  
  if (![self canDoPinModifications]) {
    failure([MoppLibError restrictedAPIError]);
    return;
  }
  
  [self verifyType:CodeTypePin1 pin:newPin1 andVerificationCode:oldPin1 success:^{
    [[CardActionsManager sharedInstance] changeCode:CodeTypePin1 withVerifyCode:oldPin1 to:newPin1 success:success failure:failure];
  } failure:failure];
}

+ (void)changePin1To:(NSString *)newPin1 withPuk:(NSString *)puk success:(VoidBlock)success failure:(FailureBlock)failure {
  
  if (![self canDoPinModifications]) {
    failure([MoppLibError restrictedAPIError]);
    return;
  }
  
  [self verifyType:CodeTypePin1 pin:newPin1 andVerificationCode:puk success:^{
    [[CardActionsManager sharedInstance] changePin:CodeTypePin1 withPuk:puk to:newPin1 success:success failure:failure];
  } failure:failure];
}

+ (void)changePin2To:(NSString *)newPin2 withOldPin2:(NSString *)oldPin2 success:(VoidBlock)success failure:(FailureBlock)failure {
  
  if (![self canDoPinModifications]) {
    failure([MoppLibError restrictedAPIError]);
    return;
  }
  
  [self verifyType:CodeTypePin2 pin:newPin2 andVerificationCode:oldPin2 success:^{
    [[CardActionsManager sharedInstance] changeCode:CodeTypePin2 withVerifyCode:oldPin2 to:newPin2 success:success failure:failure];
  } failure:failure];
}

+ (void)changePin2To:(NSString *)newPin2 withPuk:(NSString *)puk success:(VoidBlock)success failure:(FailureBlock)failure {
  
  if (![self canDoPinModifications]) {
    failure([MoppLibError restrictedAPIError]);
    return;
  }
  
  [self verifyType:CodeTypePin2 pin:newPin2 andVerificationCode:puk success:^{
    [[CardActionsManager sharedInstance] changePin:CodeTypePin2 withPuk:puk to:newPin2 success:success failure:failure];
  } failure:failure];
}

+ (void)unblockPin1WithPuk:(NSString *)puk newPin1:(NSString *)newPin1 success:(VoidBlock)success failure:(FailureBlock)failure {
  
  if (![self canDoPinModifications]) {
    failure([MoppLibError restrictedAPIError]);
    return;
  }
  
  [self verifyType:CodeTypePin1 pin:newPin1 andVerificationCode:puk success:^{
    [[CardActionsManager sharedInstance] unblockCode:CodeTypePin1 withPuk:puk newCode:newPin1 success:success failure:failure];
  } failure:failure];
}

+ (void)unblockPin2WithPuk:(NSString *)puk newPin2:(NSString *)newPin2 success:(VoidBlock)success failure:(FailureBlock)failure {
  
  if (![self canDoPinModifications]) {
    failure([MoppLibError restrictedAPIError]);
    return;
  }
  
  [self verifyType:CodeTypePin2 pin:newPin2 andVerificationCode:puk success:^{
    [[CardActionsManager sharedInstance] unblockCode:CodeTypePin2 withPuk:puk newCode:newPin2 success:success failure:failure];
  } failure:failure];
}

+ (void)verifyType:(CodeType)type pin:(NSString *)pin andVerificationCode:(NSString *)verificationCode success:(VoidBlock)success failure:(void(^)(NSError *))failure {
  
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
        [self forbiddenPinPartsForCode:type completion:^(NSArray *forbiddenPins) {
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

+ (void)forbiddenPinPartsForCode:(CodeType)type completion:(void(^)(NSArray *))complete {
  [[CardActionsManager sharedInstance] cardOwnerBirthDateWithSuccess:^(NSDate *date) {
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

+ (NSArray *)forbiddenPuks {
  return @[@"00000000", @"12345678"];
};

+ (int)pukMinLength {
  return 8;
}

+ (int)pukMaxLength {
  return 12;
}

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

+ (BOOL)canDoPinModifications {
  return [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:kRIADigiDocId];
}

@end

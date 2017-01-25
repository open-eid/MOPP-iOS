//
//  MoppLibError.h
//  MoppLib
//
//  Created by Katrin Annuk on 23/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibConstants.h"

@interface MoppLibError : NSObject

+ (NSError *)readerNotFoundError;
+ (NSError *)cardNotFoundError;
+ (NSError *)cardVersionUnknownError;
+ (NSError *)wrongPinErrorWithRetryCount:(int)count;
+ (NSError *)generalError;
+ (NSError *)invalidPinError;
+ (NSError *)pinMatchesVerificationCodeError;
+ (NSError *)incorrectPinLengthError;
+ (NSError *)tooEasyPinError;
+ (NSError *)pinContainsInvalidCharactersError;
+ (NSError *)signatureAlreadyExistsError;

@end

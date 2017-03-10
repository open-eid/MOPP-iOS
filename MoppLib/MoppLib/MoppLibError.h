//
//  MoppLibError.h
//  MoppLib
//
//  Created by Katrin Annuk on 23/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibConstants.h"

extern NSString *const MoppLibErrorDomain;

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
+ (NSError *)urlSessionCanceledError;
+ (NSError *)xmlParsingError;
+ (NSError *)DDSErrorWith:(NSInteger)errorCode;
+ (NSError *)pinNotProvidedError;
+ (NSError *)pinBlockedError;
+ (NSError *)fileNameTooLongError;
+ (NSError *)noInternetConnectionError;
@end

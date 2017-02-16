//
//  MoppLibError.m
//  MoppLib
//
//  Created by Katrin Annuk on 23/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "MoppLibError.h"

NSString *const MoppLibErrorDomain = @"MoppLibError";

@implementation MoppLibError

+ (NSError *)readerNotFoundError {
  return [self error:moppLibErrorReaderNotFound];
}

+ (NSError *)cardNotFoundError {
  return [self error:moppLibErrorCardNotFound];
}

+ (NSError *)cardVersionUnknownError {
  return [self error:moppLibErrorCardVersionUnknown];
}

+ (NSError *)wrongPinErrorWithRetryCount:(int)count {
  return [self error:moppLibErrorWrongPin userInfo:@{kMoppLibUserInfoRetryCount:[NSNumber numberWithInt:count]}];
}

+ (NSError *)generalError {
  return [self error:moppLibErrorGeneral];
}

+ (NSError *)pinBlockedError {
  return [self error:moppLibErrorPinBlocked];
}

+ (NSError *)invalidPinError {
  return [self error:moppLibErrorInvalidPin];
}

+ (NSError *)pinNotProvidedError {
  return [self error:moppLibErrorPinNotProvided];
}

+ (NSError *)pinMatchesVerificationCodeError {
  return [self error:moppLibErrorPinMatchesVerificationCode];
}

+ (NSError *)incorrectPinLengthError {
  return [self error:moppLibErrorIncorrectPinLength];
}

+ (NSError *)tooEasyPinError {
  return [self error:moppLibErrorPinTooEasy];
}

+ (NSError *)pinContainsInvalidCharactersError {
  return [self error:moppLibErrorPinContainsInvalidCharacters];
}

+ (NSError *)signatureAlreadyExistsError {
  return [self error:moppLibErrorSignatureAlreadyExists];
}
+ (NSError *)urlSessionCanceledError {
  return [self error:moppLibErrorUrlSessionCanceled];
}
+ (NSError *)xmlParsingError {
  return [self error:moppLibErrorXmlParsingError];
}

+ (NSError *)DDSErrorWith:(NSString *)message {
  return [self error:MoppLibErrorDDSError userInfo:@{NSLocalizedDescriptionKey : message}];
}

+ (NSError *)error:(NSUInteger)errorCode {
  return [self error:errorCode userInfo:nil];
}

+ (NSError *)error:(NSUInteger)errorCode userInfo:(NSDictionary *)userInfo {
  NSError *newError = [[NSError alloc] initWithDomain:@"MoppLib" code:errorCode userInfo:userInfo];
  return newError;
}

@end

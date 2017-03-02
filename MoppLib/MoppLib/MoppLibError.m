//
//  MoppLibError.m
//  MoppLib
//
//  Created by Katrin Annuk on 23/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "MoppLibError.h"

NSString *const MoppLibErrorDomain = @"MoppLibError";

typedef enum {
  kDDSErrorCodeGeneral = 100,
  kDDSErrorCodeIncorrectParameters = 101,
  kDDSErrorCodeMissingParameters = 102,
  kDDSErrorCodeOCSPUnauthorized = 103,
  kDDSErrorCodeGeneralService = 200,
  kDDSErrorCodeMissingUserCertificate = 201,
  kDDSErrorCodeCertificateValidityUnknown = 202,
  kDDSErrorCodeSessionLocked = 203,
  kDDSErrorCodeGeneralUser = 300,
  kDDSErrorCodeNotMobileIdUser = 301,
  kDDSErrorCodeUserCertificateRevoked = 302,
  kDDSErrorCodeUserCertificateStatusUnknown = 303,
  kDDSErrorCodeUserCertificateSuspended = 304,
  kDDSErrorCodeUserCertificateExpired = 305,
  kDDSErrorCodeMessageExceedsVolumeLimit = 413,
  kDDSErrorCodeSimultaneousRequestsLimitExceeded = 503
} DDSErrorCode;

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

+ (NSError *)fileNameTooLongError {
    return [self error:moppLibErrorFileNameTooLong];
}

+ (NSError *)DDSErrorWith:(NSInteger)errorCode {
  NSString *errorMessage;
  switch (errorCode) {
    case kDDSErrorCodeGeneral:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-general", nil)];
      break;
      
    case kDDSErrorCodeIncorrectParameters:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-incorrect-parameters", nil)];
      break;
    case kDDSErrorCodeMissingParameters:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-missing-parameters", nil)];
      break;
    case kDDSErrorCodeOCSPUnauthorized:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-ocsp-unauthorized", nil)];
      break;
    case kDDSErrorCodeGeneralService:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-general-service", nil)];
      break;
    case kDDSErrorCodeMissingUserCertificate:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-missing-user-certificate", nil)];
      break;
    case kDDSErrorCodeCertificateValidityUnknown:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-certificate-validity-unknown", nil)];
      break;
    case kDDSErrorCodeSessionLocked:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-session-locked", nil)];
      break;
    case kDDSErrorCodeGeneralUser:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-general-user", nil)];
      break;
    case kDDSErrorCodeNotMobileIdUser:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-not-mobile-id-user", nil)];
      break;
    case kDDSErrorCodeUserCertificateRevoked:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-user-certificate-revoked", nil)];
      break;
    case kDDSErrorCodeUserCertificateStatusUnknown:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-user-certificate-status-unknown", nil)];
      break;

    case kDDSErrorCodeUserCertificateSuspended:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-user-certificate-suspended", nil)];
      break;
    case kDDSErrorCodeUserCertificateExpired:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-user-certificate-expired", nil)];
      break;
    case kDDSErrorCodeMessageExceedsVolumeLimit:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-message-exceeds-volume-limit", nil)];
      break;
    case kDDSErrorCodeSimultaneousRequestsLimitExceeded:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-simlutaneous-requests-limit-exceeded", nil)];
      break;

      
    default:
      errorMessage = [NSString stringWithFormat:MLLocalizedErrors(@"digidoc-service-error-unknown", nil)];
      break;
  }
  return [[NSError alloc] initWithDomain:MoppLibErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
}

+ (NSError *)error:(NSUInteger)errorCode {
  return [self error:errorCode userInfo:nil];
}

+ (NSError *)error:(NSUInteger)errorCode userInfo:(NSDictionary *)userInfo {
  NSError *newError = [[NSError alloc] initWithDomain:@"MoppLib" code:errorCode userInfo:userInfo];
  return newError;
}

@end

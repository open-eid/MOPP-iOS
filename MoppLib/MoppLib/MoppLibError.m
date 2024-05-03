//
//  MoppLibError.m
//  MoppLib
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
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

#import "MoppLibError.h"
#import "MoppLibConstants.h"

NSString *const MoppLibErrorDomain = @"MoppLibError";

@implementation MoppLibError

+ (NSError *)readerNotFoundError {
  return [self error:moppLibErrorReaderNotFound withMessage:@"Reader is not commected to device."];
}

+ (NSError *)readerProcessFailedError {
  return [self error:moppLibErrorReaderProcessFailed withMessage:@"Reader process failed."];
}

+ (NSError *)readerSelectionCanceledError {
  return [self error:moppLibErrorReaderSelectionCanceled withMessage:@"User canceled reader selection."];
}

+ (NSError *)cardNotFoundError {
  return [self error:moppLibErrorCardNotFound withMessage:@"ID card could not be detected in reader."];
}
    
+ (NSError *)ldapResponseNotFoundError {
    return [self error:moppLibErrorLdapResponseNotFound withMessage:@"Ldap response is empty"];
}

+ (NSError *)duplicatedFilenameError {
    return [self error:moppLibErrorDuplicatedFilename withMessage:@"Filename already exists"];
}

+ (NSError *)cardVersionUnknownError {
  return [self error:moppLibErrorCardVersionUnknown withMessage:@"Card version could not be detected."];
}

+ (NSError *)wrongPinErrorWithRetryCount:(int)count {
  return [self error:moppLibErrorWrongPin userInfo:@{kMoppLibUserInfoRetryCount:[NSNumber numberWithInt:count]}];
}

+ (NSError *)generalError {
  return [self error:moppLibErrorGeneral withMessage:@"Could not complete action due to unknown error"];
}

+ (NSError *)pinBlockedError {
  return [self error:moppLibErrorPinBlocked userInfo:nil];
}

+ (NSError *)invalidPinError {
  return [self error:moppLibErrorInvalidPin withMessage:@"Invalid PIN"];
}

+ (NSError *)pinNotProvidedError {
  return [self error:moppLibErrorPinNotProvided withMessage:@"PIN was not provided while it was required."];
}

+ (NSError *)pinMatchesVerificationCodeError {
  return [self error:moppLibErrorPinMatchesVerificationCode withMessage:@"New PIN must be different from verification code."];
}

+ (NSError *)pinMatchesOldCodeError {
  return [self error:moppLibErrorPinMatchesOldCode withMessage:@"New PIN must be different from old PIN."];
}

+ (NSError *)incorrectPinLengthError {
  return [self error:moppLibErrorIncorrectPinLength withMessage:@"PIN length didn't pass validation. Make sure minimum and maximum length requirements are met."];
}

+ (NSError *)tooEasyPinError {
  return [self error:moppLibErrorPinTooEasy withMessage:@"New PIN code is too easy."];
}

+ (NSError *)pinContainsInvalidCharactersError {
  return [self error:moppLibErrorPinContainsInvalidCharacters withMessage:@"New PIN contains invalid characters."];
}

+ (NSError *)urlSessionCanceledError {
  return [self error:moppLibErrorUrlSessionCanceled withMessage:@"Url session canceled"];
}

+ (NSError *)xmlParsingError {
  return [self error:moppLibErrorXmlParsingError withMessage:@"XML parsing error."];
}

+ (NSError *)fileNameTooLongError {
    return [self error:moppLibErrorFileNameTooLong withMessage:@"File name is too long"];
}

+ (NSError *)noInternetConnectionError {
  return [self error:moppLibErrorNoInternetConnection withMessage:@"Internet connection not detected."];
}

+ (NSError *)sslHandshakeError {
  return [self error:moppLibErrorSslHandshakeFailed withMessage:@"Failed to create ssl connection with host."];
}

+ (NSError *)restrictedAPIError {
  return [self error:moppLibErrorRestrictedApi withMessage:@"This API method is not supported on third-party applications."];
}

+ (NSError *)tooManyRequests {
  return [self error:moppLibErrorTooManyRequests withMessage:@"digidoc-service-error-too-many-requests"];
}

+ (NSError *)ocspTimeSlotError {
  return [self error:moppLibErrorOCSPTimeSlot withMessage:@"Invalid OCSP time slot"];
}

+ (NSError *)invalidProxySettingsError {
  return [self error:moppLibErrorInvalidProxySettings withMessage:@"Invalid proxy settings"];
}

+ (NSError *)error:(NSUInteger)errorCode withMessage:(NSString *)message {
  return [self error:errorCode userInfo:@{NSLocalizedDescriptionKey : message}];
}

+ (NSError *)error:(NSUInteger)errorCode userInfo:(NSDictionary *)userInfo {
  NSError *newError = [[NSError alloc] initWithDomain:@"MoppLib" code:errorCode userInfo:userInfo];
  return newError;
}

@end

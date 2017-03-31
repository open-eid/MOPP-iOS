//
//  MoppLibConstants.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MoppLibCertData.h"
#import "MoppLibPersonalData.h"
#import "MoppLibContainer.h"
#import "MoppLibMobileCreateSignatureResponse.h"

// Mopp Lib error codes

typedef enum {
  
  moppLibErrorReaderNotFound = 10001, // Reader is not connected to phone
  moppLibErrorCardNotFound = 10002, // Reader is connected, but card is not detected
  moppLibErrorCardVersionUnknown = 10003, //
  moppLibErrorWrongPin = 10004, // Provided pin is wrong
  moppLibErrorGeneral = 10005,
  moppLibErrorInvalidPin = 10006, // New pin does not apply to rules
  moppLibErrorPinMatchesVerificationCode = 10007, // New pin must be different from old pin or puk
  moppLibErrorIncorrectPinLength = 10008, // New pin is too short or too long
  moppLibErrorPinTooEasy = 10009,// New pin is too easy
  moppLibErrorPinContainsInvalidCharacters = 10010, // Pin contains invalid characters. Only numbers are allowed
  moppLibErrorUrlSessionCanceled = 10012, // NSURLErrorCanceled occured when connecting to external service.
  moppLibErrorXmlParsingError = 10013, // AEXMLDocument loadXml failed to parse data to XML.
  MoppLibErrorDDSError = 10014, // Error from DDS
  moppLibErrorPinNotProvided = 10015, // User did not provide pin for action that required authentication
  moppLibErrorPinBlocked = 10016, // User did not provide pin for action that required authentication
  moppLibErrorFileNameTooLong = 10017, // File name too long
  moppLibErrorNoInternetConnection = 10018, // No internet connection
  moppLibErrorPinMatchesOldCode = 10019, // New pin must be different from old pin or puk
  moppLibErrorReaderSelectionCanceled = 10020 // User canceled card reader selection

} MoppLibErrorCode;

extern NSString *const kDDSServerUrl;
extern NSString *const kCreateSignatureNotificationName;
extern NSString *const kSignatureAddedToContainerNotificationName;
extern NSString *const kErrorNotificationName;
extern NSString *const kCreateSignatureResponseKey;
extern NSString *const kNewContainerKey;
extern NSString *const kOldContainerKey;
extern NSString *const kErrorKey;
extern NSString *const kCloseSessionNotificationName;
extern NSString *const kErrorMessage;
// Keys for Mopp Lib error user info

extern NSString *const kMoppLibUserInfoRetryCount;




typedef void (^DataSuccessBlock)(NSData *responseData);
typedef void (^ObjectSuccessBlock)(NSObject *responseObject);
typedef void (^FailureBlock)(NSError *error);
typedef void (^CertDataBlock)(MoppLibCertData *certData);
typedef void (^PersonalDataBlock)(MoppLibPersonalData *personalData);
typedef void (^SignatureStatusBlock) (MoppLibContainer *container, NSError *error, NSString *status);
typedef void (^ContainerBlock)(MoppLibContainer *container);
typedef void (^MobileCreateSignatureResponseBlock)(MoppLibMobileCreateSignatureResponse *createSignatureResponse);
typedef void (^VoidBlock)(void);
typedef void (^EmptySuccessBlock)();

/**
 * Posted when card reader status changes. This can be triggered when connected card reader is turned off or connected card reader detects that card is inserted or removed.
 */
extern NSString *const kMoppLibNotificationReaderStatusChanged;
extern NSString *const kMoppLibNotificationRetryCounterChanged;

//
//  MoppLibConstants.h
//  MoppLib
//
//  Created by Katrin Annuk on 22/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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
  moppLibErrorSignatureAlreadyExists = 10011 // Tried to sign document, that has been signed with this certificate already.

  
} MoppLibErrorCode;

// Keys for Mopp Lib error user info

extern NSString *const kMoppLibUserInfoRetryCount;



typedef void (^DataSuccessBlock)(NSData *responseObject);
typedef void (^ObjectSuccessBlock)(NSObject *responseObject);
typedef void (^FailureBlock)(NSError *error);
typedef void (^EmptySuccessBlock)();

/**
 * Posted when card reader status changes. This can be triggered when connected card reader is turned off or connected card reader detects that card is inserted or removed.
 */
extern NSString *const kMoppLibNotificationReaderStatusChanged;
extern NSString *const kMoppLibNotificationRetryCounterChanged;

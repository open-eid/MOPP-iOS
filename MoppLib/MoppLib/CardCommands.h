//
//  CardCommands.h
//  MoppLib
//
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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
#import "CardReaderWrapper.h"
#import "NSString+Additions.h"
#import "NSData+Additions.h"
#import "MoppLibPersonalData.h"

typedef NS_ENUM(NSUInteger, CodeType) {
  CodeTypePuk = 0,
  CodeTypePin1 = 1,
  CodeTypePin2 = 2
};

extern NSString *const kCommandSelectFileMaster;
extern NSString *const kCommandSelectFileEEEE;
extern NSString *const kCommandSelectFile0016;
extern NSString *const kCommandSelectFile5044;
extern NSString *const kCommandSelectFile;
extern NSString *const kCommandFileDDCE;
extern NSString *const kCommandFileAACE;
extern NSString *const kCommandSelectFile0013;
extern NSString *const kCommandReadRecord;
extern NSString *const kCommandReadBytes;
extern NSString *const kCommandGetCardVersion;
extern NSString *const kCommandReadBinary;
extern NSString *const kCommandChangeReferenceData;
extern NSString *const kCommandSetSecurityEnv;
extern NSString *const kCommandVerifyCode;
extern NSString *const kCommandCalculateSignature;
extern NSString *const kCommandOngoingDecryption;
extern NSString *const kCommandFinalDecryption;

extern NSString *const kCommandResetRetryCounter;


extern NSString *const kAlgorythmIdentifyerSHA1;
extern NSString *const kAlgorythmIdentifyerSHA224;
extern NSString *const kAlgorythmIdentifyerSHA256;
extern NSString *const kAlgorythmIdentifyerSHA384;
extern NSString *const kAlgorythmIdentifyerSHA512;

@protocol CardCommands <NSObject>

/**
 * Reads only minimal public data from card. That includes name, id code, birth date, nationality, document number and document expiry date.
 *
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)readMinimalPublicDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure;

/**
 * Reads public data from card.
 *
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)readPublicDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure;

/**
 * Reads authentication certificate from card.
 *
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)readAuthenticationCertificateWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure;

/**
 * Reads signature certificate from card.
 *
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)readSignatureCertificateWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure;

/**
 * Reads secret key record from card.
 *
 * @param record    Record to be read
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)readSecretKeyRecord:(NSInteger)record withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure;

/**
 * Reads pin or puk code counter record
 *
 * @param record    Record to be read
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)readCodeCounterRecord:(CodeType)record withSuccess:(NumberBlock)success failure:(FailureBlock)failure;

/**
 * Changes PIN or PUK code.
 *
 * @param type          type of code that will be changed. One of CodeTypePuk, CodeTypePin1, CodeTypePin2
 * @param code          new PIN/PUK code
 * @param verifyCode    current PIN or PUK code for verification
 * @param success       block to be executed when action is completed successfully
 * @param failure       block to be executed when action fails
 */
- (void)changeCode:(CodeType)type to:(NSString *)code withVerifyCode:(NSString *)verifyCode withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure;

/**
 * Verifies PIN or PUK code.
 *
 * @param type          type of code that will be verified. One of CodeTypePuk, CodeTypePin1, CodeTypePin2
 * @param code          your PIN/PUK code that should be verified
 * @param success       block to be executed when action is completed successfully
 * @param failure       block to be executed when action fails
 */
- (void)verifyCode:(NSString *)code ofType:(CodeType)type withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure;

/**
 * Unblocks PIN.
 *
 * @param type          type of code that will be unblocked. One of CodeTypePin1, CodeTypePin2
 * @param puk           current PUK code for verification
 * @param newCode       new code for your PIN
 * @param success       block to be executed when action is completed successfully
 * @param failure       block to be executed when action fails
 */
- (void)unblockCode:(CodeType)type withPuk:(NSString *)puk newCode:(NSString *)newCode success:(DataSuccessBlock)success failure:(FailureBlock)failure;

/**
 * Calculates signature for hash
 *
 * @param hash          hash to be signed
 * @param pin2          PIN 2 to be used for verification
 * @param success       block to be executed when action is completed successfully
 * @param failure       block to be executed when action fails
 */
- (void)calculateSignatureFor:(NSData *)hash withPin2:(NSString *)pin2 useECC:(BOOL)useECC success:(DataSuccessBlock)success failure:(FailureBlock)failure;

/**
 * Decrypt data
 *
 * @param hash          hash to be signed
 * @param pin1          PIN 1 to be used for verification
 * @param success       block to be executed when action is completed successfully
 * @param failure       block to be executed when action fails
 */
- (void)decryptData:(NSData *)hash withPin1:(NSString *)pin1 useECC:(BOOL)useECC success:(DataSuccessBlock)success failure:(FailureBlock)failure;

- (void)setSecurityEnvironment:(NSUInteger)env withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure;


@end

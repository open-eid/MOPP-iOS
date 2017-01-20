//
//  CardCommands.h
//  MoppLib
//
//  Created by Katrin Annuk on 27/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

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

typedef NS_ENUM(NSUInteger, AlgorythmType) {
  AlgorythmTypeSHA1 = 0,
  AlgorythmTypeSHA224 = 1,
  AlgorythmTypeSHA256 = 2,
  AlgorythmTypeSHA384 = 3,
  AlgorythmTypeSHA512 = 4

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
extern NSString *const kCommandResetRetryCounter;

@protocol CardCommands <NSObject>

/**
 * Reads public data from card.
 *
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)readPublicDataWithSuccess:(void (^)(MoppLibPersonalData *personalData))success failure:(FailureBlock)failure;

/**
 * Reads card owner birthDate from card.
 *
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)readBirthDateWithSuccess:(void (^)(NSDate *date))success failure:(FailureBlock)failure;

/**
 * Reads authentication certificate from card.
 *
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)readAuthenticationCertificateWithSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

/**
 * Reads signature certificate from card.
 *
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)readSignatureCertificateWithSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

/**
 * Reads secret key record from card.
 *
 * @param record    Record to be read
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)readSecretKeyRecord:(NSInteger)record withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

/**
 * Reads pin or puk code counter record
 *
 * @param record    Record to be read
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)readCodeCounterRecord:(NSInteger)record withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

/**
 * Changes PIN or PUK code.
 *
 * @param type          type of code that will be changed. One of CodeTypePuk, CodeTypePin1, CodeTypePin2
 * @param code          new PIN/PUK code
 * @param verifyCode    current PIN or PUK code for verification
 * @param success       block to be executed when action is completed successfully
 * @param failure       block to be executed when action fails
 */
- (void)changeCode:(CodeType)type to:(NSString *)code withVerifyCode:(NSString *)verifyCode withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

/**
 * Verifies PIN or PUK code.
 *
 * @param type          type of code that will be verified. One of CodeTypePuk, CodeTypePin1, CodeTypePin2
 * @param code          your PIN/PUK code that should be verified
 * @param success       block to be executed when action is completed successfully
 * @param failure       block to be executed when action fails
 */
- (void)verifyCode:(NSString *)code ofType:(CodeType)type withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

/**
 * Unblocks PIN.
 *
 * @param type          type of code that will be unblocked. One of CodeTypePin1, CodeTypePin2
 * @param puk           current PUK code for verification
 * @param newCode       new code for your PIN
 * @param success       block to be executed when action is completed successfully
 * @param failure       block to be executed when action fails
 */
- (void)unblockCode:(CodeType)type withPuk:(NSString *)puk newCode:(NSString *)newCode success:(void(^)(NSData *))success failure:(void(^)(NSError *))failure;

/**
 * Calculates signature for hash
 *
 * @param hash          hash to be signed
 * @param pin2          PIN 2 to be used for verification
 * @param success       block to be executed when action is completed successfully
 * @param failure       block to be executed when action fails
 */
- (void)calculateSignatureFor:(NSString *)hash withPin2:(NSString *)pin2 success:(void (^)(NSData *data))success failure:(FailureBlock)failure;


- (void)setSecurityEnvironment:(NSUInteger)env withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;


@end

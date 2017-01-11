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
 * Changes Pin 1 to new value
 *
 * @param newPin1       New value for pin 1 code
 * @param verifyCode    Old pin 1 or puk code for user verification
 * @param success       block to be executed when action is completed successfully
 * @param failure       block to be executed when action fails
 */
- (void)changePin1To:(NSString *)newPin1 verifyCode:(NSString *)code withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

/**
 * Changes Pin 2 to new value
 *
 * @param newPin2       New value for pin 2 code
 * @param verifyCode    Old pin 2 or puk code for user verification
 * @param success       block to be executed when action is completed successfully
 * @param failure       block to be executed when action fails
 */
- (void)changePin2To:(NSString *)newPin2 verifyCode:(NSString *)code withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

- (void)verifyPin1:(NSString *)pin1 withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

- (void)verifyPin2:(NSString *)pin2 withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

- (void)calculateSignature:(NSString *)hash withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

- (void)setSecurityEnvironment:(NSUInteger)env withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

- (void)unblockPin1WithPuk:(NSString *)puk newPin1:(NSString *)newPin1 success:(void(^)(NSData *))success failure:(void(^)(NSError *))failure;
- (void)unblockPin2WithPuk:(NSString *)puk newPin2:(NSString *)newPin2 success:(void(^)(NSData *))success failure:(void(^)(NSError *))failure;


@end

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
extern NSString *const kCommandSelectFile5044;
extern NSString *const kCommandSelectFile;
extern NSString *const kCommandFileDDCE;
extern NSString *const kCommandFileAACE;
extern NSString *const kCommandSelectFile0013;
extern NSString *const kCommandReadRecord;
extern NSString *const kCommandReadBytes;
extern NSString *const kCommandGetCardVersion;
extern NSString *const kCommandReadBinary;

@protocol CardCommands <NSObject>

/**
 * Reads public data from card.
 *
 * @param reader    Active card reader for communicating with card
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)cardReader:(id<CardReaderWrapper>)reader readPublicDataWithSuccess:(void (^)(MoppLibPersonalData *personalData))success failure:(FailureBlock)failure;

/**
 * Reads authentication certificate from card.
 *
 * @param reader    Active card reader for communicating with card
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)cardReader:(id<CardReaderWrapper>)reader readAuthenticationCertificateWithSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

/**
 * Reads signature certificate from card.
 *
 * @param reader    Active card reader for communicating with card
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)cardReader:(id<CardReaderWrapper>)reader readSignatureCertificateWithSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

/**
 * Reads secret key record from card.
 *
 * @param reader    Active card reader for communicating with card
 * @param success   block to be executed when action is completed successfully
 * @param failure   block to be executed when action fails
 */
- (void)cardReader:(id<CardReaderWrapper>)reader readSecretKeyRecord:(NSInteger)record withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

@end

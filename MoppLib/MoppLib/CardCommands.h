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
extern NSString *const kCommandSelectFileDDCE;
extern NSString *const kCommandSelectFileAACE;
extern NSString *const kCommandSelectFile0013;
extern NSString *const kCommandReadRecord;
extern NSString *const kCommandReadBytes;
extern NSString *const kCommandGetCardVersion;
extern NSString *const kCommandReadBinary;

@protocol CardCommands <NSObject>

- (void)cardReader:(id<CardReaderWrapper>)reader readPublicDataWithSuccess:(void (^)(MoppLibPersonalData *personalData))success failure:(FailureBlock)failure;
- (void)cardReader:(id<CardReaderWrapper>)reader readSignatureCertificateWithSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;
- (void)cardReader:(id<CardReaderWrapper>)reader readSecretKeyRecord:(NSInteger)record withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure;

@end

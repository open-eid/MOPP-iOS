//
//  MoppLibDigidocManager.h
//  MoppLib
//
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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
#import "MoppLibContainer.h"
#import "MoppLibSignature.h"
#import "MoppLibConstants.h"
#import "MoppLibConfiguration.h"

typedef enum {
    Unspecified,
    TimeStamp,
    TimeMark
} SigningProfileType;

@interface MoppLibDigidocManager : NSObject

@property (readonly) BOOL useTestDigiDocService;
+ (MoppLibDigidocManager *)sharedInstance;
- (void)setupWithSuccess:(VoidBlock)success andFailure:(FailureBlock)failure usingTestDigiDocService:(BOOL)useTestDDS andTSUrl:(NSString*)tsUrl withMoppConfiguration:(MoppLibConfiguration*)moppConfiguration;

- (MoppLibContainer *)getContainerWithPath:(NSString *)containerPath error:(NSError **)error;
- (MoppLibContainer *)createContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths error:(NSError **)error;
- (MoppLibContainer *)addDataFilesToContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths error:(NSError **)error;
- (MoppLibContainer *)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex error:(NSError **)error;
- (NSArray *)getContainers;
+ (NSString *)prepareSignature:(NSString *)cert containerPath:(NSString *)containerPath;
+ (void)isSignatureValid:(NSString *)cert signatureValue:(NSString *)signatureValue success:(BoolBlock)success failure:(FailureBlock)failure;
+ (NSArray *)getDataToSign;
- (NSString *)dataFileCalculateHashWithDigestMethod:(NSString *)method container:(MoppLibContainer *)moppContainer dataFileId:(NSString *)dataFileId;
- (BOOL)container:(MoppLibContainer *)moppContainer containsSignatureWithCert:(NSData *)cert;
- (void)addSignature:(NSString *)containerPath pin2:(NSString *)pin2 cert:(NSData *)cert success:(ContainerBlock)success andFailure:(FailureBlock)failure;
- (void)addMobileIDSignatureToContainer:(MoppLibContainer *)moppContainer signature:(NSString *)signature success:(ContainerBlock)success andFailure:(FailureBlock)failure;
- (MoppLibContainer *)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath error:(NSError **)error;
- (NSString *)getMoppLibVersion;
- (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path success:(VoidBlock)success failure:(FailureBlock)failure;
- (BOOL)isContainerFileSaveable:(NSString *)containerPath saveDataFile:(NSString *)fileName;
- (NSString *)digidocVersion;
- (NSString *)moppAppVersion;
- (NSString *)iOSVersion;
- (NSArray *)connectedDevices;
- (NSString *)userAgent;
- (NSString *)pkcs12Cert;
+ (NSArray *)certificatePolicyIdentifiers:(NSData *)certData;
+ (NSString *)removeBeginAndEndFromCertificate:(NSString *)certString;
+ (NSString *)sanitize:(NSString *)text;
@end

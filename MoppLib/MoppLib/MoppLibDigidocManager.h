//
//  MoppLibDigidocManager.h
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

#import "MoppLibConstants.h"

@class MoppLibConfiguration;
@class MoppLibProxyConfiguration;
@class MoppLibRoleAddressData;
@class MoppLibSignature;

@interface MoppLibDigidocManager : NSObject

+ (MoppLibDigidocManager *)sharedInstance;
- (void)setupWithSuccess:(VoidBlock)success andFailure:(FailureBlock)failure andTSUrl:(NSString*)tsUrl withMoppConfiguration:(MoppLibConfiguration*)moppConfiguration andProxyConfiguration:(MoppLibProxyConfiguration*)proxyConfiguration;

- (MoppLibContainer *)getContainerWithPath:(NSString *)containerPath error:(NSError **)error;
- (MoppLibContainer *)createContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths error:(NSError **)error;
- (MoppLibContainer *)addDataFilesToContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths error:(NSError **)error;
- (MoppLibContainer *)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex error:(NSError **)error;
- (NSArray *)getContainers;
+ (NSData *)prepareSignature:(NSData *)cert containerPath:(NSString *)containerPath roleData:(MoppLibRoleAddressData *)roleData;
+ (void)isSignatureValid:(NSData *)cert signatureValue:(NSData *)signatureValue success:(VoidBlock)success failure:(FailureBlock)failure;
- (void)addSignature:(NSString *)containerPath pin2:(NSString *)pin2 cert:(NSData *)cert roleData:(MoppLibRoleAddressData *)roleData success:(ContainerBlock)success andFailure:(FailureBlock)failure;
- (MoppLibContainer *)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath error:(NSError **)error;
- (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path success:(VoidBlock)success failure:(FailureBlock)failure;
- (BOOL)isContainerFileSaveable:(NSString *)containerPath saveDataFile:(NSString *)fileName;
@end

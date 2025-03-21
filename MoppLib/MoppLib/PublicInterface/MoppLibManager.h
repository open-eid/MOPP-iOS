//
//  MoppLibManager.h
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

@interface MoppLibManager : NSObject

+ (MoppLibManager *)sharedInstance;

/**
 * Prepares library for operations with containers. Setup must be completed before any container action is carried out. It is recommended, that you initiate setup at earliest opportunity.
 *
 * @param success       Block to be called on successful completion of action.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)setupWithSuccess:(VoidBlock)success andFailure:(FailureBlock)failure usingTestDigiDocService:(BOOL)useTestDDS andTSUrl:(NSString *)tsUrl withMoppConfiguration:(MoppLibConfiguration *)moppConfiguration andProxyConfiguration:(MoppLibProxyConfiguration*)proxyConfiguration;

+ (NSData *)prepareSignature:(NSData *)cert containerPath:(NSString *)containerPath roleData:(MoppLibRoleAddressData *)roleData;
+ (void)isSignatureValid:(NSData *)cert signatureValue:(NSData *)signatureValue success:(VoidBlock)success failure:(FailureBlock)failure;

- (NSString *)libdigidocppVersion;
- (BOOL)isConnected;
- (NSString *)appVersion;
- (NSString *)iOSVersion;
- (NSString *)userAgent;
- (NSString *)userAgent:(BOOL)shouldIncludeDevices;

@end

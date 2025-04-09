//
//  MoppLibManager.m
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

#import "MoppLibManager.h"
#import "MoppLibDigidocManager.h"
#import "../Reachability/Reachability.h"

@implementation MoppLibManager

+ (MoppLibManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)setupWithSuccess:(VoidBlock)success andFailure:(FailureBlock)failure usingTestDigiDocService:(BOOL)useTestDDS andTSUrl:(NSString *)tsUrl withMoppConfiguration:(MoppLibConfiguration *)moppConfiguration andProxyConfiguration:(MoppLibProxyConfiguration*)proxyConfiguration {
    [[MoppLibDigidocManager sharedInstance] setupWithSuccess:success andFailure:failure usingTestDigiDocService:useTestDDS andTSUrl:tsUrl withMoppConfiguration: moppConfiguration andProxyConfiguration: proxyConfiguration];
}

+ (NSData *)prepareSignature:(NSData *)cert containerPath:(NSString *)containerPath roleData:(MoppLibRoleAddressData *)roleData {
    return [MoppLibDigidocManager prepareSignature:cert containerPath:containerPath roleData:roleData];
}

+ (void)isSignatureValid:(NSData *)cert signatureValue:(NSData *)signatureValue success:(VoidBlock)success failure:(FailureBlock)failure {
    return [MoppLibDigidocManager isSignatureValid:cert signatureValue:signatureValue success:success failure:failure];
}

- (NSString *)libdigidocppVersion {
    return [[MoppLibDigidocManager sharedInstance] digidocVersion];
}

- (BOOL)isConnected {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    return [reachability currentReachabilityStatus] != NotReachable;
}

- (NSString *)appVersion {
  return [[MoppLibDigidocManager sharedInstance] moppAppVersion];
}

- (NSString *)iOSVersion {
    return [[MoppLibDigidocManager sharedInstance] iOSVersion];
}

- (NSString *)userAgent:(BOOL)shouldIncludeDevices {
    return [[MoppLibDigidocManager sharedInstance] userAgent:shouldIncludeDevices];
}

- (NSString *)userAgent {
    return [[MoppLibDigidocManager sharedInstance] userAgent:false];
}

@end

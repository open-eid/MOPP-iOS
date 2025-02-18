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

#import <ExternalAccessory/ExternalAccessory.h>
#import <UIKit/UIDevice.h>

@implementation MoppLibManager

+ (MoppLibManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)setupWithSuccess:(VoidBlock)success andFailure:(FailureBlock)failure andTSUrl:(NSString *)tsUrl withMoppConfiguration:(MoppLibConfiguration *)moppConfiguration andProxyConfiguration:(MoppLibProxyConfiguration*)proxyConfiguration {
    [[MoppLibDigidocManager sharedInstance] setupWithSuccess:success andFailure:failure andTSUrl:tsUrl withMoppConfiguration: moppConfiguration andProxyConfiguration: proxyConfiguration];
}

- (NSString *)libdigidocppVersion {
    return [[MoppLibDigidocManager sharedInstance] digidocVersion];
}

- (BOOL)isConnected {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    return [reachability currentReachabilityStatus] != NotReachable;
}

- (NSArray *)connectedDevices {
    EAAccessoryManager* accessoryManager = [EAAccessoryManager sharedAccessoryManager];
    NSMutableArray *devices = [NSMutableArray new];
    if (accessoryManager) {
        for (EAAccessory *device in [accessoryManager connectedAccessories]) {
            [devices addObject:[NSString stringWithFormat:@"%@ %@ (%@)", device.manufacturer, device.name, device.modelNumber]];
        }
    }
    return devices;
}

- (NSString *)moppAppVersion {
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    return [NSString stringWithFormat:@"%@.%@", version, build];
}

- (NSString *)appLanguage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *language = [defaults stringForKey:@"kMoppLanguage"];
    return [language length] != 0 ? [NSString stringWithFormat:@"%@", language] : [NSString stringWithFormat:@"%s", "N/A"];
}

- (NSString *)userAgent {
    return [self userAgent:false];
}

- (NSString *)userAgent:(BOOL)shouldIncludeDevices {
    NSString *appInfo = [NSString stringWithFormat:@"%s/%@ (iOS %@) Lang: %@", "riadigidoc", [self moppAppVersion],
                         UIDevice.currentDevice.systemVersion, [self appLanguage]];
    if (shouldIncludeDevices) {
        NSArray *connectedDevices = [self connectedDevices];
        if (connectedDevices.count > 0) {
            appInfo = [NSString stringWithFormat:@"%@ Devices: %@", appInfo, [connectedDevices componentsJoinedByString:@", "]];
        }
    }
    return appInfo;
}

@end

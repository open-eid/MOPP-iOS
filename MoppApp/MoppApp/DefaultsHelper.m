//
//  DefaultsHelper.m
//  MoppApp
//
//  Created by Ants Käär on 19.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "DefaultsHelper.h"

NSString *const ContainerFormatBdoc = @"bdoc";
NSString *const ContainerFormatAsice = @"asice";
NSString *const ContainerFormatDdoc = @"ddoc";

NSString *const CrashlyticsAlwaysSend = @"Always";
NSString *const CrashlyticsNeverSend = @"Never";
NSString *const CrashlyticsDefault = @"Default";

// Keys
NSString *const kNewContainerFormatKey = @"kNewContainerFormatKey";
NSString *const kPhoneNumberKey = @"kPhoneNumberKey";
NSString *const kIDCodeKey = @"kIDCodeKey";
NSString *const kCrashReportSettingKey = @"kCrashReportSettingKey";

@implementation DefaultsHelper

// New container format
+ (void)setNewContainerFormat:(NSString *)newContainerFormat {
  [[NSUserDefaults standardUserDefaults] setObject:newContainerFormat forKey:kNewContainerFormatKey];
}

+ (NSString *)getNewContainerFormat {
  NSString *newContainerFormat = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:kNewContainerFormatKey];
  return newContainerFormat;
}

+ (void)setPhoneNumber:(NSString *)phoneNumber {
  [[NSUserDefaults standardUserDefaults] setObject:phoneNumber forKey:kPhoneNumberKey];
}

+ (NSString *)getPhoneNumber {
  NSString *phoneNumber = (NSString *) [[NSUserDefaults standardUserDefaults] objectForKey:kPhoneNumberKey];
  return phoneNumber;
}

+ (void)setIDCode:(NSString *)idCode {
  [[NSUserDefaults standardUserDefaults] setObject:idCode forKey:kIDCodeKey];
}

+ (NSString *)getIDCode {
  NSString *idCode = [[NSUserDefaults standardUserDefaults] objectForKey:kIDCodeKey];
  return idCode;
}

+ (void)setCrashReportSetting:(NSString *)setting {
  return [[NSUserDefaults standardUserDefaults] setObject:setting forKey:kCrashReportSettingKey];
}

+ (NSString *)crashReportSetting {
  return [[NSUserDefaults standardUserDefaults] objectForKey:kCrashReportSettingKey];
}

@end

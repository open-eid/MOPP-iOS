//
//  DefaultsHelper.m
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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

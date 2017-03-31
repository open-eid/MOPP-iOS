//
//  DefaultsHelper.h
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

#import <Foundation/Foundation.h>

extern NSString *const ContainerFormatBdoc;
extern NSString *const ContainerFormatAsice;
extern NSString *const ContainerFormatDdoc;

extern NSString *const CrashlyticsAlwaysSend;
extern NSString *const CrashlyticsNeverSend;
extern NSString *const CrashlyticsDefault;

@interface DefaultsHelper : NSObject

// New container format
+ (void)setNewContainerFormat:(NSString *)newContainerFormat;
+ (NSString *)getNewContainerFormat;
+ (void)setPhoneNumber:(NSString *)phoneNumber;
+ (NSString *)getPhoneNumber;
+ (void)setIDCode:(NSString *)idCode;
+ (NSString *)getIDCode;

+ (void)setCrashReportSetting:(NSString *)setting;
+ (NSString *)crashReportSetting;
@end

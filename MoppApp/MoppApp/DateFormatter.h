//
//  DateFormatter.h
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

@interface DateFormatter : NSObject

+ (DateFormatter *)sharedInstance;

// 02.03.2015
- (NSString *)ddMMYYYYToString:(NSDate *)date;

// 02.03.2015
- (NSDate *)ddMMYYYYToDate:(NSString *)string;

// 17:32:06 02.03.2015
- (NSString *)HHmmssddMMYYYYToString:(NSDate *)date;

// 21. Nov OR relative string "Today" etc.
- (NSString *)dateToRelativeString:(NSDate *)date;

- (NSString *)UTCTimestampStringToLocalTime:(NSDate *)date;
@end

//
//  DateFormatter.m
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

#import "DateFormatter.h"

@interface DateFormatter ()

@property (strong, nonatomic) NSDateFormatter *ddMMYYYYDateFormatter;
@property (strong, nonatomic) NSDateFormatter *HHmmssddMMYYYYDateFormatter;
@property (strong, nonatomic) NSDateFormatter *ddMMMDateFormatter;
@property (strong, nonatomic) NSDateFormatter *relativeDateFormatter;
@property (strong, nonatomic) NSDateFormatter *nonRelativeDateFormatter;

@end

@implementation DateFormatter

+ (DateFormatter *)sharedInstance {
  static dispatch_once_t pred;
  static DateFormatter *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
    [sharedInstance initializeDateFormatters];
  });
  return sharedInstance;
}

- (void)initializeDateFormatters {
  self.ddMMYYYYDateFormatter = [NSDateFormatter new];
  self.ddMMYYYYDateFormatter.dateFormat = @"dd.MM.YYYY";
  
  self.HHmmssddMMYYYYDateFormatter = [NSDateFormatter new];
  self.HHmmssddMMYYYYDateFormatter.dateFormat = @"HH:mm:ss dd.MM.YYYY";
  
  self.ddMMMDateFormatter = [NSDateFormatter new];
  self.ddMMMDateFormatter.dateFormat = @"dd. MMM";
  
  self.relativeDateFormatter = [NSDateFormatter new];
  self.relativeDateFormatter.dateStyle = NSDateFormatterShortStyle;
  self.relativeDateFormatter.doesRelativeDateFormatting = YES;
  
  self.nonRelativeDateFormatter = [NSDateFormatter new];
  self.nonRelativeDateFormatter.dateStyle = NSDateFormatterShortStyle;
  self.nonRelativeDateFormatter.doesRelativeDateFormatting = NO;
}

// 02.03.2015
- (NSString *)ddMMYYYYToString:(NSDate *)date {
  return [self.ddMMYYYYDateFormatter stringFromDate:date];
}

// 02.03.2015
- (NSDate *)ddMMYYYYToDate:(NSString *)string {
  return [self.ddMMYYYYDateFormatter dateFromString:string];
}

// 17:32:06 02.03.2015
- (NSString *)HHmmssddMMYYYYToString:(NSDate *)date {
  return [self.HHmmssddMMYYYYDateFormatter stringFromDate:date];
}

// 21. Nov OR relative string "Today" etc.
- (NSString *)dateToRelativeString:(NSDate *)date {
  NSString *relativeString = [self.relativeDateFormatter stringFromDate:date];
  NSString *nonRelativeString = [self.nonRelativeDateFormatter stringFromDate:date];
  
  if ([relativeString isEqualToString:nonRelativeString]) {
    return [self.ddMMMDateFormatter stringFromDate:date]; // No relative date available, use custom format.
  } else {
    return relativeString; // Return relative date.
  }
}

- (NSString *)UTCTimestampStringToLocalTime:(NSDate *)date {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"HH:mm:ss dd.MM.YYYY"];
  NSTimeZone *localTimeZone = [NSTimeZone localTimeZone];
  [dateFormatter setTimeZone:localTimeZone];
  return [dateFormatter stringFromDate:date];
}
@end

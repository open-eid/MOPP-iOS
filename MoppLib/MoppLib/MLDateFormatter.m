//
//  MLDateFormatter.m
//  MoppLib
//
/*
  * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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

#import "MLDateFormatter.h"

@interface MLDateFormatter ()

@property (strong, nonatomic) NSDateFormatter *YYYYMMddTHHmmssZDateFormatter;

@end


@implementation MLDateFormatter

+ (MLDateFormatter *)sharedInstance {
  static dispatch_once_t pred;
  static MLDateFormatter *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
    [sharedInstance initializeDateFormatters];
  });
  return sharedInstance;
}

- (void)initializeDateFormatters {
  self.YYYYMMddTHHmmssZDateFormatter = [NSDateFormatter new];
  self.YYYYMMddTHHmmssZDateFormatter.dateFormat = @"YYYY-MM-dd'T'HH:mm:ss'Z'";
}

// 2013-12-10T09:11:39Z
- (NSDate *)YYYYMMddTHHmmssZToDate:(NSString *)string {
  NSDateFormatter *dateFormatter = self.YYYYMMddTHHmmssZDateFormatter;
  NSTimeZone *timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
  [dateFormatter setTimeZone:timeZone];
  return [dateFormatter dateFromString:string];
}

@end

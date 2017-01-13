//
//  DateFormatter.m
//  MoppApp
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

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
//  self.ddMMMDateFormatter.dateStyle = NSDateFormatterShortStyle;
//  self.ddMMMDateFormatter.timeStyle = NSDateFormatterShortStyle;
//  self.ddMMMDateFormatter.doesRelativeDateFormatting = YES;
  
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

@end

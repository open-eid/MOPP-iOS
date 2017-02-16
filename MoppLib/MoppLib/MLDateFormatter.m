//
//  MLDateFormatter.m
//  MoppLib
//
//  Created by Ants Käär on 09.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

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

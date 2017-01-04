//
//  NSDate+Additions.m
//  MoppApp
//
//  Created by Katrin Annuk on 04/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "NSDate+Additions.h"

@implementation NSDate (Additions)

- (NSString *)expiryDateString {
  NSDateFormatter *formatter = [NSDate formatter];
  [formatter setDateFormat:@"dd.MM.YYYY"];
  
  return [formatter stringFromDate:self];
}

+ (NSDateFormatter *)formatter {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
  return dateFormatter;
}
@end

//
//  NSString+Additions.m
//  MoppApp
//
//  Created by Katrin Annuk on 04/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "NSString+Additions.h"
#import "NSDate+Additions.h"

@implementation NSString (Additions)

- (NSDate *)expiryDateStringToDate {
  NSDateFormatter *formatter = [NSDate formatter];
  [formatter setDateFormat:@"dd.mm.YYYY"];
  return [formatter dateFromString:self];
}
@end

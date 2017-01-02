//
//  MoppLibPersonalData.m
//  MoppLib
//
//  Created by Katrin Annuk on 28/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "MoppLibPersonalData.h"

@implementation MoppLibPersonalData

- (NSString *)fullName {
  NSMutableString *name = [NSMutableString new];
  if (self.firstNameLine1.length > 0) {
    [name appendString:self.firstNameLine1];
  }
  
  if (self.firstNameLine2.length > 0) {
    if (name.length > 0) {
      [name appendString:@" "];
    }
    [name appendString:self.firstNameLine2];
  }
  
  if (self.surname.length > 0) {
    if (name.length > 0) {
      [name appendString:@" "];
    }
    [name appendString:self.surname];
  }
  
  return name;
}
@end

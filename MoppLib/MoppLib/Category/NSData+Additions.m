//
//  NSData+Additions.m
//  MoppLib
//
//  Created by Katrin Annuk on 22/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "NSData+Additions.h"
#import "NSString+Additions.h"

@implementation NSData (Additions)

- (NSString *)toHexString {
  return [self hexStringFromByteArray:[self bytes] length:[self length]];

}

- (NSString *)hexStringFromByteArray:(const uint8_t *)buffer length:(NSUInteger)length {
  
  NSString *hexString = @"";
  NSUInteger i = 0;
  
  for (i = 0; i < length; i++) {
    if (i == 0) {
      hexString = [hexString stringByAppendingFormat:@"%02X", buffer[i]];
    } else {
      hexString = [hexString stringByAppendingFormat:@" %02X", buffer[i]];
    }
  }
  
  return hexString;
}

- (const unsigned char *)responseTrailer {
  return [[self subdataWithRange:NSMakeRange(self.length - 2, 2)] bytes];
}

- (NSData *)trimmedData {
  return  [self subdataWithRange:NSMakeRange(0, self.length - 2)];
}

- (NSString *)responseString {
  //Removing trailer
  NSData *responseData = [self trimmedData];
  
  // Converting from hex to string
  NSString *string = [[responseData toHexString] hexToString];
  
  return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
@end

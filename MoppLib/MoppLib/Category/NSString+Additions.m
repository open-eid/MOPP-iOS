//
//  NSString+Additions.m
//  MoppLib
//
//  Created by Katrin Annuk on 22/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "NSString+Additions.h"
#import "NSData+Additions.h"

@implementation NSString (Additions)

- (NSString *)toHexString {
  NSData* nsData = [self dataUsingEncoding:NSUTF8StringEncoding];
  NSString* hex = [nsData toHexString];
  return hex;
}

- (NSData *)toHexData {
  NSData *byteArray = nil;
  uint8_t *buffer = NULL;
  NSUInteger i = 0;
  unichar c = 0;
  NSUInteger count = 0;
  int num = 0;
  BOOL first = YES;
  NSUInteger length = 0;
  
  // Count the number of HEX characters.
  for (i = 0; i < [self length]; i++) {
    
    c = [self characterAtIndex:i];
    if (((c >= '0') && (c <= '9')) ||
        ((c >= 'A') && (c <= 'F')) ||
        ((c >= 'a') && (c <= 'f'))) {
      count++;
    }
  }
  
  // Allocate the buffer.
  buffer = (uint8_t *) malloc((count + 1) / 2);
  if (buffer != NULL) {
    
    for (i = 0; i < [self length]; i++) {
      
      c = [self characterAtIndex:i];
      if ((c >= '0') && (c <= '9')) {
        num = c - '0';
      } else if ((c >= 'A') && (c <= 'F')) {
        num = c - 'A' + 10;
      } else if ((c >= 'a') && (c <= 'f')) {
        num = c - 'a' + 10;
      } else {
        num = -1;
      }
      
      if (num >= 0) {
        
        if (first) {
          
          buffer[length] = num << 4;
          
        } else {
          
          buffer[length] |= num;
          length++;
        }
        
        first = !first;
      }
    }
    
    // Create the byte array.
    byteArray = [NSData dataWithBytesNoCopy:buffer length:length];
  }
  
  return byteArray;

}

- (int)hexToInt {
  NSString *hexString = [self stringByReplacingOccurrencesOfString:@" " withString:@""];
  unsigned result = 0;
  NSScanner *scanner = [NSScanner scannerWithString:hexString];
  [scanner scanHexInt:&result];
  
  return result;
}

- (NSString *)hexToString {
  
  NSString *hexString = [self stringByReplacingOccurrencesOfString:@" " withString:@""];
  if (([hexString length] % 2) != 0) {
    return nil;
  }
  
  NSMutableString *string = [NSMutableString string];
  
  for (NSInteger i = 0; i < [hexString length]; i += 2) {
    
    NSString *hex = [hexString substringWithRange:NSMakeRange(i, 2)];
    NSInteger decimalValue = 0;
    sscanf([hex cStringUsingEncoding:NSASCIIStringEncoding], "%x", &decimalValue);
    [string appendFormat:@"%c", (char)decimalValue];
  }
  
  return string;
  
}
@end

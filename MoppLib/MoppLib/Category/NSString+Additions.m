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
  NSMutableString* hex = [nsData toHexString];
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
@end

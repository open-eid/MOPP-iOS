//
//  NSString+Additions.m
//  MoppLib
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
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

#import "NSString+Additions.h"
#import "NSData+Additions.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Additions)

- (NSString *)toHexString {
  NSData* nsData = [self dataUsingEncoding:NSUTF8StringEncoding];
  NSString* hex = [nsData hexString];
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

- (NSString *)replaceHexStringLastValue:(unsigned char)valueToReplace {
    NSData *data = [self toHexData];
    unsigned char *buf = (unsigned char *)[data bytes];
    buf[data.length - 1] = valueToReplace;
    return [[NSData dataWithBytes:buf length:[data length]] hexString];
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
      sscanf([hex cStringUsingEncoding:NSASCIIStringEncoding], "%lx", &decimalValue);
    [string appendFormat:@"%c", (char)decimalValue];
  }
  
  return string;
  
}
- (NSString *)SHA256 {
  const char *cStr = [self UTF8String];
  unsigned char result[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(cStr, (CC_LONG)strlen(cStr), result);
  NSString *s = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                 result[0], result[1], result[2], result[3], result[4],
                 result[5], result[6], result[7],
                 result[8], result[9], result[10], result[11], result[12],
                 result[13], result[14], result[15],
                 result[16], result[17], result[18], result[19],
                 result[20], result[21], result[22], result[23], result[24],
                 result[25], result[26], result[27],
                 result[28], result[29], result[30], result[31]
                 ];
  return [s lowercaseString];
}
@end

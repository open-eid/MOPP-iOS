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

@implementation NSString (Additions)

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

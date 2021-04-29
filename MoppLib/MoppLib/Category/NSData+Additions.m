//
//  NSData+Additions.m
//  MoppLib
//
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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

#import "NSData+Additions.h"
#import "NSString+Additions.h"

@implementation NSData (Additions)

- (NSString *)hexString {
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

- (NSData *)trailingTwoBytes {
  if (self.length >= 2)
    return [self subdataWithRange:NSMakeRange(self.length - 2, 2)];
  
  return nil;
}

- (NSData *)trailingTwoBytesTrimmed {
  if (self.length < 2)
    return nil;
    
  return  [self subdataWithRange:NSMakeRange(0, self.length - 2)];
}

- (NSString *)codePage1252String {
  //Removing trailer
  NSData *responseData = [self trailingTwoBytesTrimmed];
  NSString *string = [[NSString alloc] initWithData:responseData encoding:NSWindowsCP1252StringEncoding];
  return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)utf8String {
    NSData *responseData = [self trailingTwoBytesTrimmed];
    NSString *string = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end

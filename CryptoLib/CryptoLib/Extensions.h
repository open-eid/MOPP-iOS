//
//  Decrypt.h
//  CryptoLib
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

#import <Foundation/Foundation.h>

#include <string>
#include <vector>

@interface NSString (std_string)
- (std::string)toString;
@end

@interface NSData (std_vector)
- (std::vector<unsigned char>)toVector;
@end

@implementation NSString (std_string)
+ (instancetype)stringWithStdString:(const std::string&)data {
    return data.empty() ? nil : [NSString stringWithUTF8String:data.c_str()];
}

- (std::string)toString {
    return {self.UTF8String};
}
@end

@implementation NSData (std_vector)
+ (instancetype)dataFromVector:(const std::vector<unsigned char>&)data {
    return data.empty() ? nil : [NSData dataWithBytes:(void *)data.data() length:data.size()];
}

+ (instancetype)dataFromVectorNoCopy:(const std::vector<unsigned char>&)data {
    return data.empty() ? nil : [NSData dataWithBytesNoCopy:(void *)data.data() length:data.size() freeWhenDone:0];
}

- (std::vector<unsigned char>)toVector {
    const auto *p = reinterpret_cast<const uint8_t*>(self.bytes);
    return {p, std::next(p, self.length)};
}
@end

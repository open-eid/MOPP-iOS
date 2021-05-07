//
//  Attribute.m
//  CryptoLib
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

#import <Foundation/Foundation.h>
#import "Attribute.h"
#import "ldap.h"

@implementation Attribute

- (id)initWithParser:(LDAP*)ldap ldapMessage:(LDAPMessage*)entry tag:(char *)tag{
    if (!_values) {
        _values = [NSMutableArray new];
    }
    
    BerValue ** bvals = ldap_get_values_len(ldap, entry, tag);
    if (bvals != nil){
        for (int i = 0; bvals[i] != (void *)0; i++) {
            _name = [NSString stringWithUTF8String:tag];
            char *value = bvals[i]->bv_val;
            if ([_name isEqualToString:(@"userCertificate;binary")]){
                
                ber_len_t len = bvals[i]->bv_len;
                NSData *certificateNSData = [[NSData alloc] initWithBytes:value length:len];
                
                const UInt8 *bytes = certificateNSData.bytes;
                CFDataRef cfData = CFDataCreateWithBytesNoCopy(nil, bytes, (int)len, kCFAllocatorNull);
                SecCertificateRef certificateWithData  =  SecCertificateCreateWithData(kCFAllocatorDefault, cfData);
                
                [_values addObject:(__bridge id)certificateWithData];
            } else {
                [_values addObject:[NSString stringWithUTF8String:(value)]];
            }
            
        }
        
    }
    if (bvals != nil) {
        ldap_value_free_len(bvals);
    }
return self;
}
@end

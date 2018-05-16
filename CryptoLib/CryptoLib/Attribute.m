//
//  Attribute.m
//  CryptoLib
//
//  Created by Siim Suu on 11/05/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Attribute.h"
#import "ldap.h"

@implementation Attribute

- (id)initWithParser:(LDAP*)ldap ldapMessage:(LDAPMessage*)entry tag:(char *)tag{
    if (!_values) {
        _values = [NSMutableArray new];
    }
    
    BerValue ** bvals = ldap_get_values_len(ldap, entry, tag);
    if(bvals != nil){
        for (int i = 0; bvals[i] != '\0'; i++) {
            _name = [NSString stringWithUTF8String:tag];
            char *value = bvals[i]->bv_val;
            if([_name isEqualToString:(@"userCertificate;binary")]){
                
                ber_len_t len = bvals[i]->bv_len;
                NSData *certificateNSData = [[NSData alloc] initWithBytes:value length:len];
                
                const UInt8 *bytes = certificateNSData.bytes;
                CFDataRef cfData = CFDataCreateWithBytesNoCopy(nil, bytes, (int)len, kCFAllocatorNull);
                SecCertificateRef certificateWithData  =  SecCertificateCreateWithData(kCFAllocatorDefault, cfData);
                
                [_values addObject:(__bridge id)certificateWithData];
            }else{
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

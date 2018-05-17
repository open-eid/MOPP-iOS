//
//  AttributeSet.m
//  CryptoLib
//
//  Created by Siim Suu on 11/05/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Attribute.h"
#import "AttributeSet.h"
#import "ldap.h"

@implementation AttributeSet

- (id)initWithParser:(LDAP*)ldap ldapMessage:(LDAPMessage*)entry{
    if (!_values) {
        _values = [NSMutableArray new];
    }
    char * name= ldap_get_dn(ldap, entry);
    _name = [NSString stringWithUTF8String:name];
    BerElement * ber;
    char *firstAttribute = ldap_first_attribute(ldap, entry, &ber);
    while (firstAttribute){
        Attribute *attribute = [[Attribute alloc] initWithParser:ldap ldapMessage:entry tag:firstAttribute];
        if(attribute!=NULL){
            [_values addObject:attribute];
        }
        firstAttribute = ldap_next_attribute(ldap, entry, ber);
    }
    ber_free(ber, 0);
    return self;
}
@end

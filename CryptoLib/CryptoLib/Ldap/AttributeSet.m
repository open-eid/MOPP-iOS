//
//  AttributeSet.m
//  CryptoLib
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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
        if (attribute!=NULL){
            [_values addObject:attribute];
        }
        firstAttribute = ldap_next_attribute(ldap, entry, ber);
    }
    ber_free(ber, 0);
    return self;
}
@end

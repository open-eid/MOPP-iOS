//
//  ResultSet.m
//  CryptoLib
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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
#import "ResultSet.h"
#import "ldap.h"

@implementation ResultSet

- (id)initWithParser:(LDAP*)ldap chain:(LDAPMessage*)chain{
    if (!_values) {
        _values = [NSMutableArray new];
    }
    LDAPMessage *message = ldap_first_message(ldap, chain);
    while (message) {
        if (LDAP_RES_SEARCH_ENTRY==ldap_msgtype(message)){
            AttributeSet *attributeSet = [[AttributeSet alloc] initWithParser:ldap ldapMessage:message];
            [_values addObject:attributeSet];
        }
        message = ldap_next_message(ldap, message);
    }
    return self;
}

- (NSDictionary *) getResult{
    NSDictionary *resultDic = [NSMutableDictionary dictionary];
    for (AttributeSet *aset in _values) {
        NSDictionary *attributeDic = [NSMutableDictionary dictionary];
        for (Attribute *attribute in aset.values){
            if (attribute.values.count>1){
                [attributeDic setValue:attribute.values forKey:attribute.name];
            } else {
                [attributeDic setValue:attribute.values[0] forKey:attribute.name];
            }
        }
        [resultDic setValue:attributeDic forKey:aset.name];
    }
    return resultDic;
}
@end

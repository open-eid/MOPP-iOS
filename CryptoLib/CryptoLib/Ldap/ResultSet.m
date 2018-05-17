//
//  ResultSet.m
//  CryptoLib
//
//  Created by Siim Suu on 14/05/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

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
        if(LDAP_RES_SEARCH_ENTRY==ldap_msgtype(message)){ //TODO:
            AttributeSet *attributeSet = [[AttributeSet alloc] initWithParser:ldap ldapMessage:message];
            [_values addObject:attributeSet];
        }
        message = ldap_next_message(ldap, message);
    }
    return self;
}

- (NSDictionary *) getResult{
    NSDictionary *dic = [NSMutableDictionary dictionary];
    for(AttributeSet *aset in _values) {
        NSDictionary *d = [NSMutableDictionary dictionary];
        for(Attribute *a in aset.values){
            if(a.values.count>1){
                [d setValue:a.values forKey:a.name];
            }else{
                [d setValue:a.values[0] forKey:a.name];
            }
        }
        [dic setValue:d forKey:aset.name];
    }
    return dic;
}
@end

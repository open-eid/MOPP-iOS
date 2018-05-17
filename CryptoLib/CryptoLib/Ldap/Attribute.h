//
//  Attribute.h
//  CryptoLib
//
//  Created by Siim Suu on 11/05/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LdapResponse.h"
#import "ldap.h"

@interface Attribute : NSObject
@property (nonatomic, strong) NSMutableArray *values;
@property (nonatomic, strong) NSString *name;
- (id)initWithParser:(LDAP*)ldap ldapMessage:(LDAPMessage*)ldapMessage tag:(char*)tag;
@end



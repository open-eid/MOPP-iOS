//
//  AttributeSet.h
//  CryptoLib
//
//  Created by Siim Suu on 11/05/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LdapResponse.h"
#import "ldap.h"

@interface AttributeSet : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray *values;
- (id)initWithParser:(LDAP*)ldap ldapMessage:(LDAPMessage*)ldapMessage;
@end



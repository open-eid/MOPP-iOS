//
//  ResultSet.h
//  CryptoLib
//
//  Created by Siim Suu on 14/05/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LdapResponse.h"
#import "ldap.h"

@interface ResultSet : NSObject
@property (nonatomic, strong) NSMutableArray *values;
- (id)initWithParser:(LDAP*)ldap chain:(LDAPMessage*)chain;
- (NSDictionary *) getResult;
@end



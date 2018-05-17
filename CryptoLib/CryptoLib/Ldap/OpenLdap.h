//
//  OpenLdap.h
//  CryptoLib
//
//  Created by Siim Suu on 25/04/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LdapResponse.h"

@interface OpenLdap : NSObject
- (LdapResponse*)search:(NSString*)identityCode;
@end



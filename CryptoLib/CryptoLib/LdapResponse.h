//
//  LdapResponse.h
//  CryptoLib
//
//  Created by Siim Suu on 25/04/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LdapResponse : NSObject
@property (nonatomic, strong) NSString *givenName;
@property (nonatomic, strong) NSString *surname;
@property (nonatomic, strong) NSString *identityCode;
@property (nonatomic, strong) NSData *cert;

@end

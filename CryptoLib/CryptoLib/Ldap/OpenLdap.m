//
//  OpenLdap.m
//  CryptoLib
//
//  Created by Siim Suu on 25/04/2018.
//  Copyright © 2018 Siim Suu. All rights reserved.
//

#import "OpenLdap.h"
#import "ldap.h"
#import "ResultSet.h"

@implementation OpenLdap

- (LdapResponse*)search:(NSString*)identityCode {

    LDAP *ldap;
    LDAPMessage *msg;
    const char *base = "c=EE";
    const char *url = "ldap://ldap.sk.ee:389";
    NSString *filter = [[@"(serialNumber=" stringByAppendingString:identityCode] stringByAppendingString:@")"];
    const char *formattedFilter = [filter UTF8String];
    int ldapInitResponse = ldap_initialize(&ldap, url);
    NSDictionary *ldapResponse;
    
    
    if (ldapInitResponse == 0){
        ldap_search_ext_s(ldap, base, LDAP_SCOPE_SUBTREE, formattedFilter, nil, 0, 0, 0, 0, 0, &msg);
        if(msg != NULL){
            ResultSet *resultSet = [[ResultSet alloc] initWithParser:ldap chain:msg];
            ldapResponse = [resultSet getResult];
            
        }
    }
    
    LdapResponse *response = [[LdapResponse alloc] init];
    for (NSString* key in ldapResponse) {
        if ([key rangeOfString:@"ou=authentication"].location != NSNotFound) {
            id value = [ldapResponse objectForKey:key];
            for(NSString* innerKey in value){
                if([innerKey rangeOfString:@"userCertificate;binary"].location != NSNotFound){
                    SecCertificateRef certificate = (__bridge SecCertificateRef)([value objectForKey:innerKey]);
                    response.cert = (__bridge NSData *)(SecCertificateCopyData(certificate));
                }
                if([innerKey isEqual:@"cn"]){
                    id innerValue = [value objectForKey:innerKey];
                    NSArray *cn = [innerValue componentsSeparatedByString:@","];
                    response.surname = cn[0];
                    response.givenName = cn[1];
                    response.identityCode = cn[2];
                }
            }
        }
    }
    return response;
    
}
@end

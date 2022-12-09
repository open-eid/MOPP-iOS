//
//  OpenLdap.m
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
#import "OpenLdap.h"
#import "ldap.h"
#import "ResultSet.h"

@implementation OpenLdap

- (NSArray*)search:(NSString*)identityCode configuration:(MoppLdapConfiguration *)moppLdapConfiguration {
    NSArray *result = [self searchWith:identityCode andUrl:moppLdapConfiguration.LDAPPERSONURL];
    if (result == nil || [result count] == 0) {
        result = [self searchWith:identityCode andUrl:moppLdapConfiguration.LDAPCORPURL];
    }
    return result;
}

- (NSArray*)searchWith:(NSString*)identityCode andUrl:(NSString*)url {

    LDAP *ldap;
    LDAPMessage *msg;
    const char *base = "c=EE";
    
    BOOL secureLdap = [[url lowercaseString] hasPrefix:@"ldaps"];
    
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSString *filter;
    
    NSString *pnoeePrefix = secureLdap ? @"PNOEE-" : @"";
    NSString *wildcard = secureLdap ? @"" : @"*";
    
    if ([identityCode rangeOfCharacterFromSet:notDigits].location == NSNotFound && [identityCode length] == 11) {
        filter = [NSString stringWithFormat:@"(serialNumber=%@%@%@)", pnoeePrefix, identityCode, wildcard];
    } else if ([identityCode rangeOfCharacterFromSet:notDigits].location == NSNotFound) {
        filter = [NSString stringWithFormat:@"(serialNumber=%@)", identityCode];
    } else {
        filter = [NSString stringWithFormat:@"(cn=*%@*)", identityCode];
    }

    NSString *certificate = [[NSBundle bundleForClass:[self class]] pathForResource:@"ldapca" ofType:@"pem"];
    
    //int debugLevel = -1;
    //ldap_set_option(NULL, LDAP_OPT_DEBUG_LEVEL, &debugLevel);
    
    int ldapReturnCode;
    if (secureLdap) {
        ldapReturnCode = ldap_set_option(NULL, LDAP_OPT_X_TLS_CACERTFILE, (void *)[certificate cStringUsingEncoding:NSUTF8StringEncoding]);
        if (ldapReturnCode != LDAP_SUCCESS)
        {
            fprintf(stderr, "ldap_set_option(LDAP_OPT_X_TLS_CACERTFILE): %s\n", ldap_err2string(ldapReturnCode));
            return @[];
        };
    }
    
    const char *formattedFilter = [filter UTF8String];
    ldapReturnCode = ldap_initialize(&ldap, [url cStringUsingEncoding:NSUTF8StringEncoding]);
    NSDictionary *ldapResponse;
    
    if (secureLdap) {
        int ldap_version = LDAP_VERSION3;
        ldapReturnCode = ldap_set_option(ldap, LDAP_OPT_PROTOCOL_VERSION, &ldap_version);
        if (ldapReturnCode != LDAP_SUCCESS)
        {
            fprintf(stderr, "ldap_set_option(PROTOCOL_VERSION): %s\n", ldap_err2string(ldapReturnCode));
            ldap_unbind_ext_s(ldap, NULL, NULL);
        };
    }
    
    if (ldapReturnCode == LDAP_SUCCESS){
        ldap_search_ext_s(ldap, base, LDAP_SCOPE_SUBTREE, formattedFilter, nil, 0, 0, 0, 0, 0, &msg);
        if (msg != NULL){
            ResultSet *resultSet = [[ResultSet alloc] initWithParser:ldap chain:msg];
            ldapResponse = [resultSet getResult];
        }
        ldap_msgfree(msg);
    }
    
    NSMutableArray *response = [NSMutableArray new];
    for (NSString* key in ldapResponse) {
        Addressee *ldapRow = [[Addressee alloc] init];
        id value = [ldapResponse objectForKey:key];
        for (NSString* innerKey in value) {
            if ([innerKey rangeOfString:@"userCertificate;binary"].length != 0) {
                id certValue = ([value objectForKey:innerKey]);
                SecCertificateRef certificate;
                if ([certValue isKindOfClass: [NSArray class]]) {
                    // Do nothing with mobile-id certificate
                } else {
                    certificate = (__bridge SecCertificateRef)(certValue);
                    ldapRow.cert = (__bridge NSData *)SecCertificateCopyData(certificate);
                }
            }
            
            if ([innerKey isEqual:@"cn"]) {
                id innerValue = [value objectForKey:innerKey];
                NSArray *cn = [innerValue componentsSeparatedByString:@","];
                if (cn.count > 1) {
                    ldapRow.surname = cn[0];
                    ldapRow.givenName = cn[1];
                    ldapRow.identifier = cn[2];
                } else {
                    ldapRow.identifier = cn[0];
                    ldapRow.type = @"E-SEAL";
                }
            }
        }
        
        if(ldapRow.cert != nil) {
            [response addObject: ldapRow];
        }
    }
    
    return response;
    
}

@end

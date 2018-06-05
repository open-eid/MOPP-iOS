//
//  OpenLdap.m
//  CryptoLib
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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

- (NSMutableArray*)search:(NSString*)identityCode {

    LDAP *ldap;
    LDAPMessage *msg;
    const char *base = "c=EE";
    const char *url = "ldap://ldap.sk.ee:389";
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSString *filter;
    if ([identityCode rangeOfCharacterFromSet:notDigits].location == NSNotFound) {
        filter = [[@"(serialNumber=" stringByAppendingString:identityCode] stringByAppendingString:@")"];
    } else {
        filter = [[@"(cn=*" stringByAppendingString:identityCode] stringByAppendingString:@"*)"];
    }
    
    
    const char *formattedFilter = [filter UTF8String];
    int ldapInitResponse = ldap_initialize(&ldap, url);
    NSDictionary *ldapResponse;
    
    
    if (ldapInitResponse == 0){
        ldap_search_ext_s(ldap, base, LDAP_SCOPE_SUBTREE, formattedFilter, nil, 0, 0, 0, 0, 0, &msg);
        if (msg != NULL){
            ResultSet *resultSet = [[ResultSet alloc] initWithParser:ldap chain:msg];
            ldapResponse = [resultSet getResult];
            
        }
    }
    
    NSMutableArray *response = [[NSMutableArray alloc] init];
    for (NSString* key in ldapResponse) {
        Addressee *ldapRow = [[Addressee alloc] init];
        if (([key rangeOfString:@"ou=authentication"].location != NSNotFound) || ([key rangeOfString:@"ou=Key Encipherment"].location != NSNotFound)) {
            id value = [ldapResponse objectForKey:key];
            for (NSString* innerKey in value){
                if ([innerKey rangeOfString:@"userCertificate;binary"].location != NSNotFound){
                    id certValue = ([value objectForKey:innerKey]);
                    SecCertificateRef certificate;
                    if ([certValue isKindOfClass: [NSArray class]]) {
                        // Do nothing with mobile-id certificate
                    }else{
                        certificate = (__bridge SecCertificateRef)(certValue);
                         ldapRow.cert = (__bridge NSData *)SecCertificateCopyData(certificate);
                    }
                    
                }
                if ([innerKey isEqual:@"cn"]){
                    id innerValue = [value objectForKey:innerKey];
                    NSArray *cn = [innerValue componentsSeparatedByString:@","];
                    if (cn.count > 1) {
                        ldapRow.surname = cn[0];
                        ldapRow.givenName = cn[1];
                        ldapRow.identifier = cn[2];
                        if([key rangeOfString:@"o=ESTEID (DIGI-ID)"].location != NSNotFound){
                            ldapRow.type = @"DIGI-ID";
                        } else if ([key rangeOfString:@"o=ESTEID (MOBIIL-ID)"].location != NSNotFound){
                            ldapRow.type = @"MOBILE-ID";
                        }else {
                            ldapRow.type = @"ID-CARD";
                        }
                    }else{
                        ldapRow.identifier = cn[0];
                        ldapRow.type = @"E-SEAL";
                    }
                }
            }
        }
        if(ldapRow.cert != nil){
            [response addObject: ldapRow];
        }
    }
    return response;
    
}
@end

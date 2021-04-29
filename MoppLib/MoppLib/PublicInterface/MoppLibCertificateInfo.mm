//
//  MoppLibCertificateInfo.mm
//  MoppLib
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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

#include <digidocpp/crypto/X509Cert.h>

#import "MoppLibCertificateInfo.h"
#import <Foundation/Foundation.h>
#import <openssl/x509.h>
#import <openssl/x509v3.h>


@implementation MoppLibCertificateInfo
- (NSArray<NSString *> *)certificatePolicies:(NSData *)certificateData {
    const unsigned char *certificateDataBytes = (const unsigned char *)[certificateData bytes];
    X509 *certificateX509 = d2i_X509(NULL, &certificateDataBytes, [certificateData length]);
    digidoc::X509Cert x509 = digidoc::X509Cert(certificateX509);
    
    std::vector<std::string> x509Policies = x509.certificatePolicies();
    NSMutableArray<NSString *> *policies = [[NSMutableArray alloc] init];
    
    for (auto& policy : x509Policies) {
        [policies addObject:[NSString stringWithCString:policy.c_str() encoding:[NSString defaultCStringEncoding]]];
    }
    
    return policies;
}

- (NSArray<NSNumber *> *)keyUsages:(NSData *)certificateData {
    const unsigned char *certificateDataBytes = (const unsigned char *)[certificateData bytes];
    X509 *certificateX509 = d2i_X509(NULL, &certificateDataBytes, [certificateData length]);
    digidoc::X509Cert x509 = digidoc::X509Cert(certificateX509);
    
    NSMutableArray<NSNumber *> *keyUsagesList = [[NSMutableArray alloc] init];
    
    for (auto c : x509.keyUsage()) {
        [keyUsagesList addObject:[NSNumber numberWithInt:static_cast<int>(c)]];
    }
    
    return keyUsagesList;
}

- (BOOL) hasKeyEnciphermentUsage:(NSArray<NSNumber *> *)keyUsages {
    if ([keyUsages containsObject:@2]) {
        return true;
    }
    
    return false;
}
- (BOOL) hasKeyAgreementUsage:(NSArray<NSNumber *> *)keyUsages {
    if ([keyUsages containsObject:@4]) {
        return true;
    }
    
    return false;
}

- (BOOL) isServerAuthKeyPurpose:(NSData *)certificateData {
    const unsigned char *certificateDataBytes = (const unsigned char *)[certificateData bytes];
    X509 *certificateX509 = d2i_X509(NULL, &certificateDataBytes, [certificateData length]);
    
    const char *subjectChar = X509_NAME_oneline(X509_get_subject_name(certificateX509), NULL, 0);
    std::string subjectString(subjectChar);
    
    if (subjectString.find("SN") != std::string::npos) {
        return (X509_get_extended_key_usage(certificateX509) & XKU_SSL_SERVER) == XKU_SSL_SERVER;
    } else {
        return ((X509_get_extended_key_usage(certificateX509) != UINT32_MAX) & XKU_SSL_SERVER) == XKU_SSL_SERVER;
    }
}

- (BOOL) isTlsClientAuthKeyPurpose:(NSData *)certificateData {
    const unsigned char *certificateDataBytes = (const unsigned char *)[certificateData bytes];
    X509 *certificateX509 = d2i_X509(NULL, &certificateDataBytes, [certificateData length]);
    
    X509_check_purpose(certificateX509, -1, -1);
    if (X509_get_extended_key_usage(certificateX509) != UINT32_MAX) {
        return true;
    }
    
    return false;
}

- (BOOL) isESealType:(NSArray<NSString *> *)certificatePolicies {
    for (NSString* policy in certificatePolicies) {
        if ([policy hasPrefix: @"1.3.6.1.4.1.10015.7.3"] || [policy hasPrefix: @"1.3.6.1.4.1.10015.7.1"] || [policy hasPrefix: @"1.3.6.1.4.1.10015.2.1"]) {
            return true;
        }
        return false;
    }
    
    return false;
}
- (BOOL) isMobileIdType:(NSArray<NSString *> *)certificatePolicies {
    for (NSString* policy in certificatePolicies) {
        if ([policy hasPrefix: @"1.3.6.1.4.1.10015.1.3"] || [policy hasPrefix: @"1.3.6.1.4.1.10015.11.1"]) {
            return true;
        }
        return false;
    }
    
    return false;
}

- (BOOL) isIdCardType:(NSArray<NSString *> *)certificatePolicies {
    for (NSString* policy in certificatePolicies) {
        if ([policy hasPrefix: @"1.3.6.1.4.1.10015.1.1"] || [policy hasPrefix: @"1.3.6.1.4.1.51361.1.1.1"]) {
            return true;
        }
        return false;
    }
    
    return false;
}

- (BOOL) isDigiIdType:(NSArray<NSString *> *)certificatePolicies {
    for (NSString* policy in certificatePolicies) {
        if ([policy hasPrefix: @"1.3.6.1.4.1.10015.1.2"] || [policy hasPrefix: @"1.3.6.1.4.1.51361.1.1"] || [policy hasPrefix: @"1.3.6.1.4.1.51455.1.1"]) {
            return true;
        }
        return false;
    }
    
    return false;
}

- (BOOL) isUnknownType:(NSArray<NSString *> *)certificatePolicies {
    MoppLibCertificateInfo *certInfo = [MoppLibCertificateInfo alloc];
    if (![certInfo isIdCardType:(certificatePolicies)] && ![certInfo isDigiIdType:(certificatePolicies)] && ![certInfo isMobileIdType:(certificatePolicies)] && ![certInfo isESealType:(certificatePolicies)]) {
        return true;
    }
    
    return false;
}

@end

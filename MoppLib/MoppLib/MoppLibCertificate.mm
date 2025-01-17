//
//  MoppLibCertificate.m
//  MoppLib
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
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

#import "MoppLibCertificate.h"
#import "MoppLibManager.h"
#include <digidocpp/crypto/X509Cert.h>
#include <digidocpp/Exception.h>
#import <openssl/x509.h>

@implementation MoppLibCertificate

+ (void)certData:(MoppLibCerificatetData *)certData updateWithDerEncoding:(NSData*)data {
    try {
        auto bytes = reinterpret_cast<const unsigned char*>(data.bytes);
        digidoc::X509Cert cert(bytes, data.length);
        if (!cert) {
            return;
        }
        certData.isValid = cert.isValid();
        certData.expiryDate = [self certificateExpiryDate:cert];
        certData.organization = [self certificateOrganization:cert];
    } catch(const digidoc::Exception &e) {
        printLog(@"Code: %u, message: %@", e.code(), [NSString stringWithCString:e.msg().c_str() encoding:[NSString defaultCStringEncoding]]);
    }
}

+ (MoppLibCertificateOrganization)certificateOrganization:(const digidoc::X509Cert&)cert {
    NSMutableArray *policies = [NSMutableArray new];
    for (const std::string &policy: cert.certificatePolicies()) {
        [policies addObject:[NSString stringWithUTF8String:policy.c_str()]];
    }

    for (NSString *policyID in policies) {
        if ([policyID hasPrefix:@"1.3.6.1.4.1.10015.1.1"]
            || [policyID hasPrefix:@"1.3.6.1.4.1.51361.1.1.1"])
            return IDCard;
        else if ([policyID hasPrefix:@"1.3.6.1.4.1.10015.1.2"]
            || [policyID hasPrefix:@"1.3.6.1.4.1.51361.1.1"]
            || [policyID hasPrefix:@"1.3.6.1.4.1.51455.1.1"])
            return DigiID;
        else if ([policyID hasPrefix:@"1.3.6.1.4.1.10015.1.3"]
            || [policyID hasPrefix:@"1.3.6.1.4.1.10015.11.1"])
            return MobileID;
        else if ([policyID hasPrefix:@"1.3.6.1.4.1.10015.7.3"]
            || [policyID hasPrefix:@"1.3.6.1.4.1.10015.7.1"]
            || [policyID hasPrefix:@"1.3.6.1.4.1.10015.2.1"])
            return ESeal;
    }
    return Unknown;
}

+ (NSDate *)certificateExpiryDate:(const digidoc::X509Cert&)cert {
    if (auto *certificateExpiryASN1Generalized = ASN1_TIME_to_generalizedtime(X509_get0_notAfter(cert.handle()), nil)) {
        const unsigned char *certificateExpiryData = ASN1_STRING_get0_data(certificateExpiryASN1Generalized);
        NSString *expiryTimeStr = [NSString stringWithUTF8String:(char *)certificateExpiryData];
        ASN1_GENERALIZEDTIME_free(certificateExpiryASN1Generalized);

        NSDateComponents *expiryDateComponents = [[NSDateComponents alloc] init];
        expiryDateComponents.year   = [[expiryTimeStr substringWithRange:NSMakeRange(0, 4)] intValue];
        expiryDateComponents.month  = [[expiryTimeStr substringWithRange:NSMakeRange(4, 2)] intValue];
        expiryDateComponents.day    = [[expiryTimeStr substringWithRange:NSMakeRange(6, 2)] intValue];
        expiryDateComponents.hour   = [[expiryTimeStr substringWithRange:NSMakeRange(8, 2)] intValue];
        expiryDateComponents.minute = [[expiryTimeStr substringWithRange:NSMakeRange(10, 2)] intValue];
        expiryDateComponents.second = [[expiryTimeStr substringWithRange:NSMakeRange(12, 2)] intValue];

        NSCalendar *calendar = [NSCalendar currentCalendar];
        return [calendar dateFromComponents:expiryDateComponents];
    }
    return nil;
}

@end

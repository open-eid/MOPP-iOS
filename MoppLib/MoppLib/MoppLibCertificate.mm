//
//  MoppLibCertificate.m
//  MoppLib
//
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

#import "MoppLibCertificate.h"
#import "MoppLibManager.h"
#include <digidocpp/crypto/X509Cert.h>
#include <digidocpp/exception.h>
#import <openssl/x509.h>
#import <openssl/x509v3.h>
#include <iostream>

@implementation MoppLibCertificate

+ (void)certData:(MoppLibCerificatetData *)certData updateWithDerEncodingData:(const unsigned char *)data length:(size_t)length {
    try {
        digidoc::X509Cert digiDocCert = digidoc::X509Cert(data, length, digidoc::X509Cert::Format::Der);
        [self setCertData:certData digiDocCert:digiDocCert];
    } catch (digidoc::Exception e) {
        printf("%s\n", e.msg().c_str());
    }
}

+ (void)certData:(MoppLibCerificatetData *)certData updateWithPemEncodingData:(const unsigned char *)data length:(size_t)length {
    digidoc::X509Cert digiDocCert = digidoc::X509Cert(data, length, digidoc::X509Cert::Format::Pem);
    [self setCertData:certData digiDocCert:digiDocCert];
}

+ (void)setCertData:(MoppLibCerificatetData *)certData digiDocCert:(digidoc::X509Cert)digiDocCert {
    certData.isValid = [self certificateIsValid:digiDocCert];
    certData.expiryDate = [self certificateExpiryDate:digiDocCert];
    certData.organization = [self certificateOrganization:digiDocCert];
}

+ (MoppLibCertificateOrganization)certificateOrganization:(digidoc::X509Cert)cert {
    X509 *certificateX509 = cert.handle();
    
    if (certificateX509 != NULL) {
        std::string name(certificateX509->name);
        
        NSMutableArray *policies = [NSMutableArray new];
        for (int i=0; i<cert.certificatePolicies().size(); i++) {
            [policies addObject:[NSString stringWithUTF8String:cert.certificatePolicies()[i].c_str()]];
        }
        EIDType eidType = [MoppLibManager eidTypeFromCertificatePolicies:policies];
        
        switch (eidType) {
            case EIDTypeUnknown:
            case EIDTypeESeal:
                return Unknown;
            case EIDTypeMobileID:
                return MobileID;
            case EIDTypeDigiID:
                return DigiID;
            case EIDTypeIDCard:
                return IDCard;
        }
    }
    return Unknown;
}

+ (NSDate *)certificateExpiryDate:(digidoc::X509Cert)cert {
    
    X509 *certificateX509 = cert.handle();
    
    NSDate *expiryDate = nil;
    
    if (certificateX509 != NULL) {
        ASN1_TIME *certificateExpiryASN1 = X509_get_notAfter(certificateX509);
        if (certificateExpiryASN1 != NULL) {
            ASN1_GENERALIZEDTIME *certificateExpiryASN1Generalized = ASN1_TIME_to_generalizedtime(certificateExpiryASN1, NULL);
            if (certificateExpiryASN1Generalized != NULL) {
                unsigned char *certificateExpiryData = ASN1_STRING_data(certificateExpiryASN1Generalized);
                
                NSString *expiryTimeStr = [NSString stringWithUTF8String:(char *)certificateExpiryData];
                NSDateComponents *expiryDateComponents = [[NSDateComponents alloc] init];
                
                expiryDateComponents.year   = [[expiryTimeStr substringWithRange:NSMakeRange(0, 4)] intValue];
                expiryDateComponents.month  = [[expiryTimeStr substringWithRange:NSMakeRange(4, 2)] intValue];
                expiryDateComponents.day    = [[expiryTimeStr substringWithRange:NSMakeRange(6, 2)] intValue];
                expiryDateComponents.hour   = [[expiryTimeStr substringWithRange:NSMakeRange(8, 2)] intValue];
                expiryDateComponents.minute = [[expiryTimeStr substringWithRange:NSMakeRange(10, 2)] intValue];
                expiryDateComponents.second = [[expiryTimeStr substringWithRange:NSMakeRange(12, 2)] intValue];
                
                NSCalendar *calendar = [NSCalendar currentCalendar];
                expiryDate = [calendar dateFromComponents:expiryDateComponents];
            }
        }
    }
    
    return expiryDate;
}

+ (BOOL)certificateIsValid:(digidoc::X509Cert)cert {
    return cert.isValid();
}

@end

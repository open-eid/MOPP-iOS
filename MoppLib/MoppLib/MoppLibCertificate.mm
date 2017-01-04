//
//  MoppLibCertificate.m
//  MoppLib
//
//  Created by Katrin Annuk on 04/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "MoppLibCertificate.h"
#include <digidocpp/crypto/X509Cert.h>
#import <openssl/x509.h>

@implementation MoppLibCertificate

+ (void)certData:(MoppLibCertData *)certData updateWithData:(const unsigned char *)data length:(size_t)length {
  digidoc::X509Cert digiDocCert = [self digidocCertFrom:data length:length];
  
  certData.isValid = [self certificateIsValid:digiDocCert];
  certData.expiryDate = [self certificateExpiryDate:digiDocCert];
}

+ (digidoc::X509Cert)digidocCertFrom:(const unsigned char *)certData length:(size_t)length {
  digidoc::X509Cert cert = digidoc::X509Cert(certData, length, digidoc::X509Cert::Format::Der);
  return cert;
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

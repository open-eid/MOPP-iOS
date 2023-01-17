//
//  MoppLibCryptoActions.m
//  MoppLib
//
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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

#import "MoppLibCryptoActions.h"
#import "MoppLibError.h"
#import "CryptoLib/Addressee.h"
#import "CryptoLib/CryptoDataFile.h"
#import "CryptoLib/OpenLdap.h"
#import "CryptoLib/Encrypt.h"
#import "CryptoLib/Decrypt.h"
#import "CryptoLib/CdocParser.h"
#import "MoppLibCertificate.h"
#import "CryptoLib/CdocInfo.h"
#import "SmartToken.h"
#include <stdio.h>
#include <openssl/x509.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#import "NSData+Additions.h"
#include "MoppLibDigidocMAnager.h"
#import "MoppLibCertificateInfo.h"
#import "MoppLibManager.h"
#import "Reachability.h"

@implementation MoppLibCryptoActions
    
+ (MoppLibCryptoActions *)sharedInstance {
    static dispatch_once_t pred;
    static MoppLibCryptoActions *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)parseCdocInfo:(NSString *)fullPath success:(CdocContainerBlock)success failure:(FailureBlock)failure {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        CdocInfo *response;
         @try {
            CdocParser *cdocParser = [CdocParser new];
            response = [cdocParser parseCdocInfo:fullPath];
            if (response.addressees == nil || response.dataFiles == nil) {
                 error = [MoppLibError generalError];
            }
            for (Addressee* addressee in response.addressees) {
                MoppLibCerificatetData *certData = [MoppLibCerificatetData new];
                NSData *certificate = addressee.cert;
                
                addressee.policyIdentifiers = [MoppLibDigidocManager certificatePolicyIdentifiers:certificate];
                
                NSString* certificateWithUTF8 = [NSString stringWithUTF8String:[certificate bytes]];
                //Sometimes there may be a redundant line change
                NSString *formattedCertificate = [certificateWithUTF8 stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
                NSData* decodedCertificate = [formattedCertificate dataUsingEncoding:NSUTF8StringEncoding];

                [MoppLibCertificate certData:certData updateWithPemEncodingData:[decodedCertificate bytes] length:decodedCertificate.length certString:(formattedCertificate)];
                addressee.type = [self formatTypeToString :certData.organization];
                addressee.validTo = certData.expiryDate;
            }
         }
        @catch (...) {
            error = [MoppLibError generalError];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            error == nil ? success(response) : failure(error);
        });
    });
}

- (NSString*)formatTypeToString:(MoppLibCertificateOrganization)formatType {
    NSString *result = nil;
    switch(formatType) {
        case DigiID:
            result = @"DIGI-ID";
            break;
        case IDCard:
            result = @"ID-CARD";
            break;
        default:
            result = @"E-SEAL";
            break;
    }
    
    return result;
}

- (void)decryptData:(NSString *)fullPath withPin1:(NSString*)pin1 success:(DecryptedDataBlock)success failure:(FailureBlock)failure {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        NSMutableDictionary *response;
        @try {
            Decrypt *decrypter = [Decrypt new];
            SmartToken *smartToken = [SmartToken new];
            response = [decrypter decryptFile:fullPath withPin:pin1 withToken:smartToken];
            if (response.count==0) {
                error = [MoppLibError generalError];
            }
        }
        @catch (NSException *exception) {
            if([[exception name] hasPrefix:@"wrong_pin"]) {
                // Last character of wrong_pin shows retry count
                NSString *retryCount = [[exception name] substringFromIndex: [[exception name] length] - 1];
                if ([retryCount intValue] < 1) {
                    error = [MoppLibError pinBlockedError];
                } else {
                    error = [MoppLibError wrongPinErrorWithRetryCount:[retryCount intValue]];
                }
            } else if ([[exception name] isEqualToString:@"pin_blocked"]) {
                error = [MoppLibError pinBlockedError];
            } else {
                error = [MoppLibError generalError];
            }
        }
        @catch (...) {
            error = [MoppLibError generalError];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            error == nil ? success(response) : failure(error);
        });
    });
}

- (void)encryptData:(NSString *)fullPath withDataFiles:(NSArray*)dataFiles withAddressees:(NSArray*)addressees success:(VoidBlock)success failure:(FailureBlock)failure {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        @try {
            Encrypt *encrypter = [[Encrypt alloc] init];
            [encrypter encryptFile:fullPath withDataFiles:dataFiles withAddressees:addressees];
        }
        @catch (...) {
            error = [MoppLibError generalError];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            error == nil ? success() : failure(error);
        });
    });
}

- (MoppLibCertificateOrganization)parseEIDType:(NSArray<NSString *>*)certPolicies {
    
    EIDType eidType = [MoppLibManager eidTypeFromCertificatePolicies:certPolicies];
    
    switch (eidType) {
        case EIDTypeUnknown:
        case EIDTypeESeal:
            return Unknown;
        case EIDTypeMobileID:
            return MobileID;
        case EIDTypeSmartID:
            return SmartID;
        case EIDTypeDigiID:
            return DigiID;
        case EIDTypeIDCard:
            return IDCard;
    }
    return Unknown;
}
    
- (void)searchLdapData:(NSString *)identifier success:(LdapBlock)success failure:(FailureBlock)failure configuration:(MoppLdapConfiguration *) moppLdapConfiguration {
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
      failure([MoppLibError noInternetConnectionError]);
      return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *response = [[NSMutableArray alloc] init];
        NSMutableArray *filteredResponse = [[NSMutableArray alloc] init];
        NSError *error;
        OpenLdap *ldap = [[OpenLdap alloc] init];
        @try {
            response = [ldap search:identifier configuration:moppLdapConfiguration];
            
            if (response.count == 0) {
                failure([MoppLibError ldapResponseNotFoundError]);
                return;
            }
            
            for (Addressee* key in response) {
                const unsigned char *certificateDataBytes;
                certificateDataBytes = (unsigned char*) [key.cert bytes];
                
                X509 *certificateX509 = d2i_X509(NULL, &certificateDataBytes, [key.cert length]);
                if (certificateX509 != NULL) {
                    ASN1_TIME *certificateExpiryASN1 = X509_get_notAfter(certificateX509);
                    if (certificateExpiryASN1 != NULL) {
                        ASN1_GENERALIZEDTIME *certificateExpiryASN1Generalized = ASN1_TIME_to_generalizedtime(certificateExpiryASN1, NULL);
                        if (certificateExpiryASN1Generalized != NULL) {
                            
                            MoppLibCertificateInfo *certInfo = [MoppLibCertificateInfo alloc];
                            NSArray<NSString *> *certPolicies = [certInfo certificatePolicies:(key.cert)];
                            NSArray<NSNumber *> *certKeyUsages = [certInfo keyUsages:(key.cert)];
                            
                            if (key.type == nil) {
                                key.type = [self formatTypeToString:[self parseEIDType:certPolicies]];
                            }
                            
                            if (([certInfo hasKeyEnciphermentUsage:(certKeyUsages)] || [certInfo hasKeyAgreementUsage:(certKeyUsages)]) &&
                                ![certInfo isServerAuthKeyPurpose:(key.cert)] &&
                                (![certInfo isESealType:(certPolicies)] || ![certInfo isTlsClientAuthKeyPurpose:(key.cert)]) &&
                                ![certInfo isMobileIdType:(certPolicies)] && ![certInfo isUnknownType:(certPolicies)]) {
                                
                                const unsigned char *certificateExpiryData = ASN1_STRING_get0_data(certificateExpiryASN1Generalized);
                                
                                // ASN1 generalized times look like this: "20131114230046Z"
                                //                                format:  YYYYMMDDHHMMSS
                                //                               indices:  01234567890123
                                //                                                   1111
                                // There are other formats (e.g. specifying partial seconds or
                                // time zones) but this is good enough for our purposes since
                                // we only use the date and not the time.
                                //
                                // (Source: http://www.obj-sys.com/asn1tutorial/node14.html)
                                
                                NSString *expiryTimeStr = [NSString stringWithUTF8String:(char *)certificateExpiryData];
                                NSDateComponents *expiryDateComponents = [[NSDateComponents alloc] init];
                                
                                expiryDateComponents.year   = [[expiryTimeStr substringWithRange:NSMakeRange(0, 4)] intValue];
                                expiryDateComponents.month  = [[expiryTimeStr substringWithRange:NSMakeRange(4, 2)] intValue];
                                expiryDateComponents.day    = [[expiryTimeStr substringWithRange:NSMakeRange(6, 2)] intValue];
                                expiryDateComponents.hour   = [[expiryTimeStr substringWithRange:NSMakeRange(8, 2)] intValue];
                                expiryDateComponents.minute = [[expiryTimeStr substringWithRange:NSMakeRange(10, 2)] intValue];
                                expiryDateComponents.second = [[expiryTimeStr substringWithRange:NSMakeRange(12, 2)] intValue];
                                
                                NSCalendar *calendar = [NSCalendar currentCalendar];
                                key.validTo = [calendar dateFromComponents:expiryDateComponents];
                                
                                [filteredResponse addObject:(key)];
                                
                            }
                        }
                    }
                }
                
            }
        }
        @catch (...) {
            error = [MoppLibError generalError];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            error == nil ? success(filteredResponse) : failure(error);
        });
    });
}

@end

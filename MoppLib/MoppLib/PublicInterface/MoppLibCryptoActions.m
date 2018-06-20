//
//  MoppLibCryptoActions.m
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
            for (Addressee* addressee in response.addressees) {
                MoppLibCerificatetData *certData = [MoppLibCerificatetData new];
                NSData *certificate = addressee.cert;
                NSString* certificateWithUTF8 = [NSString stringWithUTF8String:[certificate bytes]];
                //Sometimes there may be a redundant line change
                NSString *formattedCertificate = [certificateWithUTF8 stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
                NSData* decodedCertificate = [formattedCertificate dataUsingEncoding:NSUTF8StringEncoding];

                [MoppLibCertificate certData:certData updateWithDataPem:[decodedCertificate bytes] length:decodedCertificate.length];
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
        }
        @catch (NSException *exception) {
            if([[exception name] isEqualToString:@"Wrong PIN"]) {
                error = [MoppLibError wrongPinErrorWithRetryCount:[[exception reason] intValue]];
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
    
- (void)searchLdapData:(NSString *)identifier success:(LdapBlock)success failure:(FailureBlock)failure {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *response = [[NSMutableArray alloc] init];
        NSError *error;
        OpenLdap *ldap = [[OpenLdap alloc] init];
        @try {
            response = [ldap search:identifier];
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
                            unsigned char *certificateExpiryData = ASN1_STRING_data(certificateExpiryASN1Generalized);
                            
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
                            
                        }
                    }
                }
              
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
    
    @end

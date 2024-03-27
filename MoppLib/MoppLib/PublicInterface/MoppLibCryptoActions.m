//
//  MoppLibCryptoActions.m
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
                addressee.policyIdentifiers = [MoppLibDigidocManager certificatePolicyIdentifiers:addressee.cert];
                [MoppLibCertificate certData:certData updateWithDerEncoding:addressee.cert];
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
    
    NSString *certsPath = [self getLibraryCertsFolderPath];
    NSString *ldapCertsPath = [self getCertFolderPath:certsPath fileName:@"ldapCerts.pem"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<LDAPResponse *> *response = [[NSMutableArray alloc] init];
        NSMutableArray<Addressee *> *filteredResponse = [[NSMutableArray alloc] init];
        NSError *error;
        OpenLdap *ldap = [[OpenLdap alloc] init];
        @try {
            response = [ldap search:identifier configuration:moppLdapConfiguration withCertificate:ldapCertsPath];
            
            if (response.count == 0) {
                failure([MoppLibError ldapResponseNotFoundError]);
                return;
            }
            
            for (LDAPResponse* key in response) {
                for (NSString *cert in key.userCertificate) {
                    
                    Addressee *addressee = [[Addressee alloc] init];
                    
                    SecCertificateRef certificate = (__bridge SecCertificateRef)(cert);
                    NSData* certData = (__bridge NSData *)SecCertificateCopyData(certificate);

                    MoppLibCertificateInfo *certInfo = [MoppLibCertificateInfo alloc];
                    NSArray<NSString *> *certPolicies = [certInfo certificatePolicies:(certData)];
                    NSArray<NSNumber *> *certKeyUsages = [certInfo keyUsages:(certData)];
                    
                    addressee.policyIdentifiers = certPolicies;

                    if (key.cn != NULL) {
                        NSArray *cn = [key.cn componentsSeparatedByString:@","];
                        if (cn.count > 1) {
                            addressee.surname = cn[0];
                            addressee.givenName = cn[1];
                            addressee.identifier = cn[2];
                        } else {
                            addressee.identifier = cn[0];
                            addressee.type = @"E-SEAL";
                        }
                    }

                    if (addressee.type == nil) {
                        addressee.type = [self formatTypeToString:[self parseEIDType:certPolicies]];
                    }
                    
                    if (([certInfo hasKeyEnciphermentUsage:(certKeyUsages)] || [certInfo hasKeyAgreementUsage:(certKeyUsages)]) &&
                        ![certInfo isServerAuthKeyPurpose:(certData)] &&
                        (![certInfo isESealType:(certPolicies)] || ![certInfo isTlsClientAuthKeyPurpose:(certData)]) &&
                        ![certInfo isMobileIdType:(certPolicies)] && ![certInfo isUnknownType:(certPolicies)]) {
                        
                        addressee.cert = certData;
                        
                        MoppLibCerificatetData *certificateData = [MoppLibCerificatetData new];
                        [MoppLibCertificate certData:certificateData updateWithDerEncoding:certData];
                        addressee.validTo = certificateData.expiryDate;
                        if (addressee.validTo != nil) {
                            [filteredResponse addObject:addressee];
                        }
                    }
                }
            }

            if (filteredResponse.count == 0) {
                failure([MoppLibError ldapResponseNotFoundError]);
                return;
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

- (NSString*) getLibraryCertsFolderPath {
    NSArray *libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    if ([libraryPaths count] > 0) {
        NSString *libraryPath = libraryPaths[0];
        NSString *certsPath = [libraryPath stringByAppendingPathComponent:@"LDAPCerts"];
        return certsPath;
    }
    return nil;
}

- (NSString*) getCertFolderPath:(NSString *)directoryPath fileName:(NSString *)fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
    if ([fileManager fileExistsAtPath:filePath]) {
        return filePath;
    } else {
        NSLog(@"File %@ does not exist at directory path: %@", fileName, filePath);
    }
    
    return @"";
}

@end

//
//  MoppLibSignature.h
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

#import <Foundation/Foundation.h>
#import "MoppLibConstants.h"

@interface MoppLibSignature : NSObject

@property (strong, nonatomic) NSString *subjectName;
@property (strong, nonatomic) NSDate *timestamp;
@property (assign, nonatomic) MoppLibSignatureStatus status;
@property (strong, nonatomic) NSString *issuerName;
@property (strong, nonatomic) NSString *trustedSigningTime;

@property (strong, nonatomic) NSString *signersCertificateIssuer;
@property (strong, nonatomic) NSData *signingCertificate;
@property (strong, nonatomic) NSString *signatureMethod;
@property (strong, nonatomic) NSString *containerFormat;
@property (strong, nonatomic) NSString *signatureFormat;
@property (assign, nonatomic) NSInteger signedFileCount;
@property (strong, nonatomic) NSString *signatureTimestamp;
@property (strong, nonatomic) NSString *signatureTimestampUTC;
@property (strong, nonatomic) NSString *hashValueOfSignature;
@property (strong, nonatomic) NSString *tsCertificateIssuer;
@property (strong, nonatomic) NSData *tsCertificate;
@property (strong, nonatomic) NSString *ocspCertificateIssuer;
@property (strong, nonatomic) NSData *ocspCertificate;
@property (strong, nonatomic) NSString *ocspTime;
@property (strong, nonatomic) NSString *ocspTimeUTC;
@property (strong, nonatomic) NSString *signersMobileTimeUTC;

@end

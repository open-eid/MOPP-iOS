//
//  Idemia.m
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

#import "Idemia.h"
#import "NSData+Additions.h"
#import "NSString+Additions.h"
#import "MoppLibError.h"
#import <CommonCrypto/CommonDigest.h>


const NSString *kAID = @"00 A4 04 00 10 A0 00 00 00 77 01 08 00 07 00 00 FE 00 00 01 00";
const NSString *kAID_QSCD = @"00 A4 04 0C 10 51 53 43 44 20 41 70 70 6C 69 63 61 74 69 6F 6E";
const NSString *kSelectMasterFile = @"00 A4 00 0C";
const NSString *kSelectRecord = @"00 A4 01 0C 02 50 %02X";
const NSString *kReadBinary = @"00 B0 %02X %02X 00";
const NSString *kSelectPersonalFile = @"00 A4 01 0C 02 50 00";
const NSString *kSelectAuthAdf = @"00 A4 01 0C 02 AD F1";
const NSString *kSelectAuthCert = @"00 A4 01 0C 02 34 01";
const NSString *kSelectSignAdf = @"00 A4 01 0C 02 AD F2 00";
const NSString *kSelectSignCert = @"00 A4 02 04 02 34 1F 00";
const NSString *kReadCodeCounter = @"00 CB 3F FF 0A 4D 08 70 06 BF 81 %02X 02 A0 80 00";
const NSString *kChangeCode = @"00 24 00 %02X %02X";
const NSString *kVerify = @"00 20 00 %02X %02X";

@implementation Idemia

- (void)readMinimalPublicDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure {
    [_reader transmitCommand:kAID success:^(NSData *responseData) {
        [_reader transmitCommand:kSelectMasterFile success:^(NSData *responseData) {
            [_reader transmitCommand:kSelectPersonalFile success:^(NSData *responseData) {
                MoppLibPersonalData *personalData = [MoppLibPersonalData new];
                __block BOOL failureOccurred = NO;
                for (int recordNr = 1; recordNr < 16 && !failureOccurred; recordNr++) {
                    NSString *cmd = [NSString stringWithFormat:kSelectRecord, recordNr];
                    [_reader transmitCommand:cmd success:^(NSData *responseData) {
                        NSString *readBinaryCmd = [NSString stringWithFormat:kReadBinary, 0, 0];
                        
                        [_reader transmitCommand:readBinaryCmd success:^(NSData *responseData) {
                            NSString *record = [responseData utf8String];
                            switch (recordNr) {
                            case 1: personalData.surname = record; break;
                            case 2: personalData.firstNameLine1 = record; break;
                            case 3: personalData.sex = record; break;
                            case 4: personalData.nationality = record; break;
                            case 5: {
                                    if ([record length] > 0) {
                                        NSArray *arr = [record componentsSeparatedByString:@" "];
                                        personalData.birthDate = arr[0];
                                        personalData.birthPlace = arr[1];
                                    }
                                }
                                break;
                            case 6: personalData.personalIdentificationCode = record; break;
                            case 7: personalData.documentNumber = record; break;
                            case 8: personalData.expiryDate = record; break;
                            case 9: personalData.dateIssued = record; break;
                            case 10: personalData.residentPermitType = record; break;
                            case 11: personalData.notes1 = record; break;
                            case 12: personalData.notes2 = record; break;
                            case 13: personalData.notes3 = record; break;
                            case 14: personalData.notes4 = record; break;
                            }
                        } failure:^(NSError* error){ failure(error); failureOccurred = YES; }];
                    } failure:^(NSError* error){ failure(error); failureOccurred = YES; }];
                }
                if (!failureOccurred) {
                    success(personalData);
                }
            } failure:failure];
        } failure:failure];
    } failure:failure];
}

- (void)readPublicDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure {
    [self readMinimalPublicDataWithSuccess:success failure:failure];
}

- (void)readBinaryRecursivelyWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure data:(NSData*)data {
    __block Idemia *me = self;
    NSString *readBinaryCmd = [NSString stringWithFormat:kReadBinary,
        (UInt8)(data.length >> 8),
        (UInt8)data.length
    ];
    [_reader transmitCommand:readBinaryCmd success:^(NSData *responseData) {
        bool done = false;
        if(responseData.length > 1) {
            UInt8 *bytes = (UInt8*)responseData.bytes;
            if(bytes[responseData.length-2] == 0x6B
                && bytes[responseData.length-1] == 0x00) {
                done = true;
            }
        }
        if (done) {
            success(data);
        } else {
            NSMutableData *newData = [[NSMutableData alloc] initWithData:data];
            [newData appendData:[responseData subdataWithRange:NSMakeRange(0, responseData.length-2)]];
            
            [me readBinaryRecursivelyWithSuccess:success failure:failure data:newData];
        }
    } failure:failure];
}

- (void)readAuthenticationCertificateWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [_reader transmitCommand:kAID success:^(NSData *responseData) {
        [_reader transmitCommand:kSelectMasterFile success:^(NSData *responseData) {
            [_reader transmitCommand:kSelectAuthAdf success:^(NSData *responseData) {
                [_reader transmitCommand:kSelectAuthCert success:^(NSData *responseData) {
                    [self readBinaryRecursivelyWithSuccess:success failure:failure data:[NSData new]];
                } failure:failure] ;
            } failure:failure];
        } failure:failure];
    } failure:failure];
}

- (void)readSignatureCertificateWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [_reader transmitCommand:kAID success:^(NSData *responseData) {
        [_reader transmitCommand:kSelectMasterFile success:^(NSData *responseData) {
            [_reader transmitCommand:kSelectSignAdf success:^(NSData *responseData) {
                [_reader transmitCommand:kSelectSignCert success:^(NSData *responseData) {
                    [self readBinaryRecursivelyWithSuccess:success failure:failure data:[NSData new]];
                } failure:failure] ;
            } failure:failure];
        } failure:failure];
    } failure:failure];
}

- (void)readSecretKeyRecord:(NSInteger)record withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    
}

- (void)readCodeCounterRecord:(CodeType)codeType withSuccess:(NumberBlock)success failure:(FailureBlock)failure {
    UInt8 recordNr = 0;
    NSString *aid;
    switch (codeType) {
        case CodeTypePin1:
            recordNr = 1;
            aid = kAID;
            break;
        case CodeTypePin2:
            recordNr = 5;
            aid = kAID_QSCD;
            break;
        case CodeTypePuk:
            recordNr = 2;
            aid = kAID;
            break;
    }
    
    [_reader transmitCommand:aid success:^(NSData *responseData) {
        [_reader transmitCommand:[NSString stringWithFormat:kReadCodeCounter, recordNr] success:^(NSData *responseData) {
            NSNumber *counter = [NSNumber numberWithUnsignedChar:((UInt8 *)responseData.bytes)[13]];
            success(counter);
        } failure:failure];
    } failure:failure];
}

- (NSData *)pinTemplate:(NSString *)pin {
    NSMutableData *result = [pin dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger paddingSize = 12 - result.length;
    for (int i=0; i<paddingSize; i++) {
        UInt8 ch[1] = { 0xFF };
        [result appendBytes:ch length:1];
    }
    return result;
}

- (void)changeCode:(CodeType)type to:(NSString *)code withVerifyCode:(NSString *)verifyCode withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    NSData *newPin = [self pinTemplate:code];
    NSData *pin = [self pinTemplate:verifyCode];
    NSString *aid, *cmd;
    UInt8 recordNr;
    switch (type) {
        case CodeTypePin1:
            aid = kAID;
            recordNr = 1;
            break;
        case CodeTypePin2:
            aid = kAID_QSCD;
            recordNr = 0x85;
            break;
        case CodeTypePuk:
            aid = kAID;
            recordNr = 2;
            break;
    }
    cmd = [NSString stringWithFormat:kChangeCode, recordNr, pin.length + newPin.length];
    [_reader transmitCommand:aid success:^(NSData *responseData) {
        NSMutableData *fullCmd = [NSMutableData dataWithData:[cmd toHexData]];
        [fullCmd appendData:pin];
        [fullCmd appendData:newPin];
        [_reader transmitCommand:[fullCmd hexString] success:^(NSData *responseData) {
            NSError *error = [self errorForPinActionResponse:responseData];
            if (error) {
                failure(error);
            } else {
                success(responseData);
            }
        } failure:failure];
    } failure:failure];
}

- (NSError *)errorForPinActionResponse:(NSData *)response {
  NSData *trailerData = [response trailingTwoBytes];
  const unsigned char *trailer = [trailerData bytes];
  
  if (trailerData.length >= 2 && trailer[0] == 0x90 && trailer[1] == 0x00) {
    // Action was completed successfully. No error here
    return nil;
    
  } else if (trailerData.length >= 1 && trailer[0] == 0x63) {
    //  For pin codes this means verification failed due to wrong pin
    NSString *dataHex = [trailerData hexString];
    // Last char in trailer holds retry count
    NSString *retryCount = [dataHex substringFromIndex:dataHex.length - 1];
    return [MoppLibError wrongPinErrorWithRetryCount:retryCount.intValue];
    
  } else if (trailerData.length >= 2 && trailer[0] == 0x6A && trailer[1] == 0x80) {
    // New pin is invalid
    return [MoppLibError pinMatchesOldCodeError];
      
  } else if (trailerData.length >= 2 && trailer[0] == 0x69 && trailer[1] == 0x83) {
    // Authentication method blocked
    return [MoppLibError pinBlockedError];
  }
    
  return [MoppLibError generalError];
}

- (void)verifyCode:(NSString *)code ofType:(CodeType)type withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    NSData *pin = [self pinTemplate:code];
    NSString *aid;
    UInt8 recordNr;
    switch (type) {
    case CodeTypePin1:
        aid = kAID;
        recordNr = 1;
        break;
    case CodeTypePin2:
        aid = kAID_QSCD;
        recordNr = 0x85;
        break;
    case CodeTypePuk:
        aid = kAID;
        recordNr = 2;
        break;
    }
    NSString *cmd = [NSString stringWithFormat:kVerify, recordNr, (UInt8)aid.length];
    [_reader transmitCommand:aid success:^(NSData *responseData) {
        NSMutableData *fullCmd = [NSMutableData dataWithData:[cmd toHexData]];
        [fullCmd appendData:pin];
        [_reader transmitCommand:[fullCmd hexString] success:^(NSData *responseData) {
            NSError *error = [self errorForPinActionResponse:responseData];
            if (error) {
                failure(error);
            } else {
                success(responseData);
            }
        } failure:failure];
    } failure:failure];
}

- (void)unblockCode:(CodeType)type withPuk:(NSString *)puk newCode:(NSString *)newCode success:(DataSuccessBlock)success failure:(FailureBlock)failure {

}

- (void)calculateSignatureFor:(NSData *)hash withPin2:(NSString *)pin2 useECC:(BOOL)useECC success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    
}

- (void)decryptData:(NSData *)hash withPin1:(NSString *)pin1 useECC:(BOOL)useECC success:(DataSuccessBlock)success failure:(FailureBlock)failure {

}

- (void)setSecurityEnvironment:(NSUInteger)env withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {

}

@end

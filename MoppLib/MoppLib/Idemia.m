//
//  Idemia.m
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

#import "Idemia.h"

#import "CardReaderWrapper.h"
#import "NSData+Additions.h"
#import "NSString+Additions.h"
#import "MoppLibError.h"
#import "MoppLibPersonalData.h"

NSString *kAID = @"00 A4 04 0C 10 A0 00 00 00 77 01 08 00 07 00 00 FE 00 00 01 00";
NSString *kAID_QSCD = @"00 A4 04 0C 10 51 53 43 44 20 41 70 70 6C 69 63 61 74 69 6F 6E";
NSString *kAID_Oberthur = @"00 A4 04 0C 0D E8 28 BD 08 0F F2 50 4F 54 20 41 57 50";
NSString *kSelectPersonalFile = @"00 A4 01 0C 02 50 00";
NSString *kSelectRecord = @"00 A4 02 0C 02 50 %02X";
NSString *kSelectAuthCert = @"00 A4 09 0C 04 AD F1 34 01";
NSString *kSelectSignCert = @"00 A4 09 0C 04 AD F2 34 1F";
NSString *kReadCodeCounter = @"00 CB 3F FF 0A 4D 08 70 06 BF 81 %02X 02 A0 80 00";
NSString *kReadBinary = @"00 B0 %02X %02X E7";
NSString *kChangeCode = @"00 24 00 %02X %02X %@ %@";
NSString *kVerify = @"00 20 00 %02X %02X %@";
NSString *kReplaceCode = @"00 2C 02 %02X %02X %@";
NSString *kSetSecEnvAuth = @"00 22 41 A4 09 80 04 FF 20 08 00 84 01 81";
NSString *kSetSecEnvSign = @"00 22 41 B6 09 80 04 FF 15 08 00 84 01 9F";
NSString *kSetSecEnvDerive = @"00 22 41 B8 09 80 04 FF 30 04 00 84 01 81";
NSString *kAuth = @"00 88 00 00 %02X %@ 00";
NSString *kSign = @"00 2A 9E 9A %02X %@ 00";
NSString *kDerive = @"00 2A 80 86 %02X 00 %@ 00";

@implementation Idemia

- (void)readPublicDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure {
    [_reader transmitCommand:kAID success:^(NSData *responseData) {
        [self->_reader transmitCommand:kSelectPersonalFile success:^(NSData *responseData) {
            MoppLibPersonalData *personalData = [MoppLibPersonalData new];
            __block BOOL failureOccurred = NO;
            for (int recordNr = 1; recordNr < 16 && !failureOccurred; recordNr++) {
                NSString *cmd = [NSString stringWithFormat:kSelectRecord, recordNr];
                [self->_reader transmitCommand:cmd success:^(NSData *responseData) {
                    NSString *readBinaryCmd = [NSString stringWithFormat:kReadBinary, 0, 0];
                    [self->_reader transmitCommand:readBinaryCmd success:^(NSData *responseData) {
                        NSData *utf8 = [responseData trailingTwoBytesTrimmed];
                        NSString *record = [[NSString alloc] initWithData:utf8 encoding:NSUTF8StringEncoding];
                        //record = [record stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        switch (recordNr) {
                        case 1: personalData.surname = record; break;
                        case 2: personalData.givenNames = record; break;
                        case 3: personalData.sex = record; break;
                        case 4: personalData.nationality = [record length] > 0 ? record : @"-"; break;
                        case 5: {
                                if ([record class] == [NSString class]) {
                                    NSArray *arr = [record componentsSeparatedByString:@" "];
                                    if (arr.count > 1) {
                                        personalData.birthDate = arr[0];
                                        personalData.birthPlace = arr[1];
                                    }
                                } else {
                                    personalData.birthDate = @"-";
                                    personalData.birthPlace = @"-";
                                }
                            }
                            break;
                        case 6: personalData.personalIdentificationCode = record; break;
                        case 7: personalData.documentNumber = record; break;
                        case 8: personalData.expiryDate = [self expiryDateEstFormatWith:record]; break;
                        case 9: personalData.dateIssued = record; break;
                        case 10: personalData.residentPermitType = record; break;
                        case 11: personalData.notes1 = record; break;
                        case 12: personalData.notes2 = record; break;
                        case 13: personalData.notes3 = record; break;
                        case 14: personalData.notes4 = record; break;
                        }
                    } failure:^(NSError* error){ failureOccurred = YES; failure(error); }];
                } failure:^(NSError* error){ failureOccurred = YES; failure(error); }];
            }
            if (!failureOccurred) {
                success(personalData);
            }
        } failure:failure];
    } failure:failure];
}

- (NSString*)expiryDateEstFormatWith:(NSString*)record {
    return [record stringByReplacingOccurrencesOfString:@" "
        withString:@"."
        options:0
        range:NSMakeRange(0, record.length)];
}

- (void)readBinaryRecursivelyWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure data:(NSMutableData*)data {
    NSString *readBinaryCmd = [NSString stringWithFormat:kReadBinary,
        (UInt8)(data.length >> 8),
        (UInt8)data.length
    ];
    [_reader transmitCommand:readBinaryCmd success:^(NSData *responseData) {
        if([responseData sw] == 0x6B00) {
            return success(data);
        }
        [data appendData:[responseData trailingTwoBytesTrimmed]];
        [self readBinaryRecursivelyWithSuccess:success failure:failure data:data];
    } failure:failure];
}

- (void)readAuthenticationCertificateWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [_reader transmitCommand:kAID success:^(NSData *responseData) {
        [self->_reader transmitCommand:kSelectAuthCert success:^(NSData *responseData) {
            [self readBinaryRecursivelyWithSuccess:success failure:failure data:[NSMutableData new]];
        } failure:failure];
    } failure:failure];
}

- (void)readSignatureCertificateWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [_reader transmitCommand:kAID success:^(NSData *responseData) {
        [self->_reader transmitCommand:kSelectSignCert success:^(NSData *responseData) {
            [self readBinaryRecursivelyWithSuccess:success failure:failure data:[NSMutableData new]];
        } failure:failure];
    } failure:failure];
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
        [self->_reader transmitCommand:[NSString stringWithFormat:kReadCodeCounter, recordNr] success:^(NSData *responseData) {
            NSNumber *counter = [NSNumber numberWithUnsignedChar:((UInt8 *)responseData.bytes)[13]];
            success(counter);
        } failure:failure];
    } failure:failure];
}

- (NSData *)pinTemplate:(NSString *)pin {
    NSMutableData *result = [[pin dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    UInt8 padding = 0xFF;
    while (result.length < 12) {
        [result appendBytes:&padding length:1];
    }
    return result;
}

- (void)changeCode:(CodeType)type to:(NSString *)code withVerifyCode:(NSString *)verifyCode withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
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
    [_reader transmitCommand:aid success:^(NSData *responseData) {
        NSData *newPin = [self pinTemplate:code];
        NSData *pin = [self pinTemplate:verifyCode];
        NSString *change = [NSString stringWithFormat:kChangeCode, recordNr, pin.length + newPin.length, [pin hexString], [newPin hexString]];
        [self->_reader transmitCommand:change success:^(NSData *responseData) {
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
    UInt16 sw = [response sw];
    switch (sw) {
        case 0x9000: // Action was completed successfully. No error here
            return nil;
        case 0x6A80: // New pin is invalid
            return [MoppLibError pinMatchesOldCodeError];
        case 0x63C1: // For pin codes this means verification failed due to wrong pin
        case 0x63C2: // Last char in trailer holds retry count
            return [MoppLibError wrongPinErrorWithRetryCount:sw & 0x000f];
        case 0x63C0:
        case 0x6983: // Authentication method blocked
            return [MoppLibError pinBlockedError];
        default:
            return [MoppLibError generalError];
    }
}

- (void)verifyCode:(NSString *)code ofType:(CodeType)type withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
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
    [_reader transmitCommand:aid success:^(NSData *responseData) {
        NSData *pin = [self pinTemplate:code];
        NSString *verify = [NSString stringWithFormat:kVerify, recordNr, pin.length, [pin hexString]];
        [self->_reader transmitCommand:verify success:^(NSData *responseData) {
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
    if (type == CodeTypePuk)
        return;
    NSString *aid = type == CodeTypePin1 ? kAID : kAID_QSCD;
    [self verifyCode:puk ofType:CodeTypePuk withSuccess:^(NSData *responseData) {
        [self->_reader transmitCommand:aid success:^(NSData *responseData) {
            NSData *pin = [self pinTemplate:newCode];
            NSString *replaceCmd = [NSString stringWithFormat:kReplaceCode, type == CodeTypePin1 ? 1 : 0x85, pin.length, [pin hexString]];
            [self->_reader transmitCommand:replaceCmd success:^(NSData *responseData) {
                NSError *error = [self errorForPinActionResponse:responseData];
                if (error) {
                    failure(error);
                } else {
                    success(responseData);
                }
            } failure:failure];
        } failure:failure];
    } failure:failure];
}

- (void)authenticateFor:(NSData *)hash withPin1:(NSString *)pin1 success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self verifyCode:pin1 ofType:CodeTypePin1 withSuccess:^(NSData *responseData) {
        [self->_reader transmitCommand:kAID_Oberthur success:^(NSData *responseData) {
            [self->_reader transmitCommand:kSetSecEnvAuth success:^(NSData *responseData) {
                NSUInteger paddedHashLength = MAX(48, hash.length);
                NSMutableData *paddedHash = [NSMutableData dataWithLength:paddedHashLength - hash.length];
                [paddedHash appendData:hash];
                NSString *signApdu = [NSString stringWithFormat:kAuth, paddedHashLength, [paddedHash hexString]];
                [self->_reader transmitCommand:signApdu success:^(NSData *responseData) {
                    success([responseData trailingTwoBytesTrimmed]);
                } failure:failure];
            } failure:failure];
        } failure:failure];
    } failure:failure];
}

- (void)calculateSignatureFor:(NSData *)hash withPin2:(NSString *)pin2 success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self verifyCode:pin2 ofType:CodeTypePin2 withSuccess:^(NSData *responseData) {
        [self->_reader transmitCommand:kAID_QSCD success:^(NSData *responseData) {
            [self->_reader transmitCommand:kSetSecEnvSign success:^(NSData *responseData) {
                NSUInteger paddedHashLength = MAX(48, hash.length);
                NSMutableData *paddedHash = [NSMutableData dataWithLength:paddedHashLength - hash.length];
                [paddedHash appendData:hash];
                NSString *signApdu = [NSString stringWithFormat:kSign, paddedHashLength, [paddedHash hexString]];
                [self->_reader transmitCommand:signApdu success:^(NSData *responseData) {
                    success([responseData trailingTwoBytesTrimmed]);
                } failure:failure];
            } failure:failure];
        } failure:failure];
    } failure:failure];
}

- (void)decryptData:(NSData *)publicKey withPin1:(NSString *)pin1 success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self verifyCode:pin1 ofType:CodeTypePin1 withSuccess:^(NSData *responseData) {
        [self->_reader transmitCommand:kAID_Oberthur success:^(NSData *responseData) {
            [self->_reader transmitCommand:kSetSecEnvDerive success:^(NSData *responseData) {
                NSString *decryptApdu = [NSString stringWithFormat:kDerive, [publicKey length] + 1, [publicKey hexString]];
                [self.reader transmitCommand:decryptApdu success:^(NSData *responseData) {
                    success([responseData trailingTwoBytesTrimmed]);
                } failure:failure];
            } failure:failure];
        } failure:failure];
    } failure:failure];
}

@end

//
//  EstEIDv3_4.m
//  MoppLib
//
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

#import "EstEIDv3_4.h"
#import "NSData+Additions.h"
#import "NSString+Additions.h"
#import "MoppLibError.h"
#import <CommonCrypto/CommonDigest.h>

NSString *const kCardErrorCorruptDataWarning = @"62 81";
NSString *const kCardErrorEndOfFile = @"62 82";
NSString *const kCardErrorFileInvalid = @"62 83";
NSString *const kCardErrorCorruptDataError = @"64 00";
NSString *const kCardErrorMemoryFailure = @"65 81";
NSString *const kCardErrorTinyLe = @"67 00";
NSString *const kCardErrorNoKeyReference = @"69 00";
NSString *const kCardErrorIncompatibleFileStructure = @"69 81";
NSString *const kCardErrorSecurityStatusNotSatified = @"69 82";
NSString *const kCardErrorAuthenticationBlocked = @"69 83";
NSString *const kCardErrorReferenceDataInvalidated = @"69 84";
NSString *const kCardErrorCommandExecutionOrder = @"69 85";
NSString *const kCardErrorCommandNotAllowed = @"69 86";
NSString *const kCardErrorSmDataObjectsMissing = @"69 87";
NSString *const kCardErrorSmDataObjectsIncorrect = @"69 88";
NSString *const kCardErrorSmWithoutSessionkeys = @"69 89";
NSString *const kCardErrorIncorrectDatafield = @"6A 80";
NSString *const kCardErrorFileNotFound = @"6A 82";
NSString *const kCardErrorRecordNotFound = @"6A 83";
NSString *const kCardErrorNotEnoughMemorySpace = @"6A 84";
NSString *const kCardErrorIncorrectParameter = @"6A 86";
NSString *const kCardErrorLcInconsistent = @"6A 87";
NSString *const kCardErrorReferenceDataNotFound = @"6A 88";
NSString *const kCardErrorFileExist = @"6A 89";
NSString *const kCardErrorDfNameExist = @"6A 8A";
NSString *const kCardErrorWrongParameters = @"6B 00";
NSString *const kCardErrorInstructionCodeNotSupported = @"6D 00";
NSString *const kCardErrorClassNotSupported = @"6E 00";
NSString *const kCardErrorNoPreciseDiagnosis = @"6F 00";

@implementation EstEIDv3_4

- (void)readAuthenticationCertificateWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
  [self readCertificate:kCommandFileAACE WithSuccess:success failure:failure];
}

- (void)readSignatureCertificateWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
  [self readCertificate:kCommandFileDDCE WithSuccess:^(NSData *data) {
    success([data trailingTwoBytesTrimmed]);
  } failure:failure];
}

- (void)readMinimalPublicDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure {
  MoppLibPersonalData *personalData = [MoppLibPersonalData new];
  void (^readSurname)(void) = [self readRecord:1 success:^(NSData *responseObject) {
    personalData.surname = [responseObject codePage1252String];
    success(personalData);
  } failure:failure];
  
  void (^readFirstNameLine1)(void) = [self readRecord:2 success:^(NSData *responseObject) {
    personalData.firstNameLine1 = [responseObject codePage1252String];
    readSurname();
  } failure:failure];
  
  void (^readFirstNameLine2)(void) = [self readRecord:3 success:^(NSData *responseObject) {
    personalData.firstNameLine2 = [responseObject codePage1252String];
    readFirstNameLine1();
  } failure:failure];
  
  void (^readNationality)(void) = [self readRecord:5 success:^(NSData *responseObject) {
    personalData.nationality = [responseObject codePage1252String];
    readFirstNameLine2();
  } failure:failure];
  
  void (^readBirthDate)(void) = [self readRecord:6 success:^(NSData *responseObject) {
    personalData.birthDate = [responseObject codePage1252String];
    readNationality();
  } failure:failure];
  
  void (^readIdCode)(void) = [self readRecord:7 success:^(NSData *responseObject) {
    personalData.personalIdentificationCode = [responseObject codePage1252String];
    readBirthDate();
  } failure:failure];
  
  void (^readDocumentNr)(void) = [self readRecord:8 success:^(NSData *responseObject) {
    personalData.documentNumber = [responseObject codePage1252String];
    readIdCode();
  } failure:failure];
  
  void (^readExpiryDate)(void) = [self readRecord:9 success:^(NSData *responseObject) {
    personalData.expiryDate = [responseObject codePage1252String];
    readDocumentNr();
  } failure:failure];
  
  
  [self navigateToFile5044WithSuccess:^(NSData *responseObject) {
    readExpiryDate();
  } failure:failure];
}

- (void)readPublicDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure {
  
  [self readMinimalPublicDataWithSuccess:^(MoppLibPersonalData *personalData) {
    
    void (^readSex)(void) = [self readRecord:4 success:^(NSData *responseObject) {
      personalData.sex = [responseObject codePage1252String];
      success(personalData);
    } failure:failure];
    
    void (^readDateIssued)(void) = [self readRecord:11 success:^(NSData *responseObject) {
      personalData.dateIssued = [responseObject codePage1252String];
      readSex();
    } failure:failure];
    
    void (^readTypeOfPermit)(void) = [self readRecord:12 success:^(NSData *responseObject) {
      personalData.residentPermitType = [responseObject codePage1252String];
      readDateIssued();
    } failure:failure];
    
    void (^readNotes1)(void) = [self readRecord:13 success:^(NSData *responseObject) {
      personalData.notes1 = [responseObject codePage1252String];
      readTypeOfPermit();
    } failure:failure];
    
    void (^readNotes2)(void) = [self readRecord:14 success:^(NSData *responseObject) {
      personalData.notes2 = [responseObject codePage1252String];
      readNotes1();
    } failure:failure];
    
    void (^readNotes3)(void) = [self readRecord:15 success:^(NSData *responseObject) {
      personalData.notes3 = [responseObject codePage1252String];
      readNotes2();
    } failure:failure];
    
    void (^readNotes4)(void) = [self readRecord:16 success:^(NSData *responseObject) {
      personalData.notes4 = [responseObject codePage1252String];
      readNotes3();
    } failure:failure];
    
    readNotes4();
  } failure:failure];
}

- (void)readBirthDateWithSuccess:(void (^)(NSDate *date))success failure:(FailureBlock)failure {
  void (^readBirthDate)(void) = [self readRecord:6 success:^(NSData *responseObject) {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd.MM.yyyy"];
    NSString *dateString = [responseObject codePage1252String];
    success([dateFormatter dateFromString:dateString]);
    
  } failure:failure];
                                 
  [self navigateToFile5044WithSuccess:^(NSData *responseObject) {
    readBirthDate();
  } failure:failure];
}

- (void)readSecretKeyRecord:(NSInteger)record withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
  void (^readRecord)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:[NSString stringWithFormat:kCommandReadRecord, record] success:^(NSData *responseObject) {
      success(responseObject);
      
    } failure:failure];
  };
  
  void (^select0013)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:kCommandSelectFile0013 success:readRecord failure:failure];
  };
  
  [self navigateToFileEEEEWithSuccess:select0013 failure:failure];
}

- (void)readCodeCounterRecord:(CodeType)record withSuccess:(NumberBlock)success failure:(FailureBlock)failure {
  if (record == CodeTypePuk) {
    record = 3;
  }
  void (^readRecord)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:[NSString stringWithFormat:kCommandReadRecord, record] success:^(NSData *responseData) {
        success([self retryCountFromData:responseData]);
    } failure:failure];
  };
  
  void (^select0016)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:kCommandSelectFile0016 success:readRecord failure:failure];
  };
  
  [self.reader transmitCommand:kCommandSelectFileMaster success:select0016 failure:failure];
}

- (NSNumber *)retryCountFromData:(NSData *)data {
    const unsigned char *dataBytes = [data bytes];
    for (int i = 0; i < [data length]; i++) {
        if (dataBytes[i] == 0x90) {
            if ([data length] > i + 1) {
                NSData *lengthData = [data subdataWithRange:NSMakeRange(i + 1, 1)];
                int length = [[lengthData hexString] hexToInt];
                
                if ([data length] > i + 1 + length) {
                    NSData *counterData = [data subdataWithRange:NSMakeRange(i + 2, length)];
                    int countValue = [[counterData hexString] hexToInt];
                    
                    return [NSNumber numberWithInt:countValue];
                }
            }
        }
    }
    
    return nil;
}

- (void)changeCode:(CodeType)type to:(NSString *)code withVerifyCode:(NSString *)verifyCode withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
  NSString *commandSufix = [NSString stringWithFormat:@"%@ %@", [verifyCode toHexString], [code toHexString]];
  NSString *command = [NSString stringWithFormat:kCommandChangeReferenceData, type, code.length + verifyCode.length, commandSufix];
  [self.reader transmitCommand:command success:^(NSData *responseObject) {
    [self checkPinErrors:responseObject success:success failure:failure]();
  } failure:failure];
}

- (void)calculateSignatureFor:(NSData *)hash withPin2:(NSString *)pin2 useECC:(BOOL)useECC success:(DataSuccessBlock)success failure:(FailureBlock)failure {
  void (^calculateSignature)(NSData *) = ^void (NSData *responseObject) {
    NSString *algorithmIdentifyer;
    switch (hash.length) {
      case CC_SHA1_DIGEST_LENGTH:
        algorithmIdentifyer = kAlgorythmIdentifyerSHA1;
        break;
        
      case CC_SHA224_DIGEST_LENGTH:
        algorithmIdentifyer = kAlgorythmIdentifyerSHA224;
        break;
        
      case CC_SHA256_DIGEST_LENGTH:
        algorithmIdentifyer = kAlgorythmIdentifyerSHA256;
        break;
        
      case CC_SHA384_DIGEST_LENGTH:
        algorithmIdentifyer = kAlgorythmIdentifyerSHA384;
        break;
        
      case CC_SHA512_DIGEST_LENGTH:
        algorithmIdentifyer = kAlgorythmIdentifyerSHA512;
        break;
        
      default:
        break;
    }
    
    NSString *commandSuffix;
    
    if (useECC)
        commandSuffix = [NSString stringWithFormat:@"%02lX %@", hash.length, [hash hexString]];
    else
        commandSuffix = [NSString stringWithFormat:@"%02lX %@ %@", hash.length + algorithmIdentifyer.length / 2, algorithmIdentifyer, [hash hexString]];
    
    [self.reader transmitCommand:[NSString stringWithFormat:kCommandCalculateSignature, commandSuffix] success:^(NSData *responseObject) {
      success([responseObject trailingTwoBytesTrimmed]);
    } failure:failure];
  };
  
  void (^verifyPin2)(NSData *) = ^void (NSData *responseObject) {
    [self verifyCode:pin2 ofType:CodeTypePin2 withSuccess:calculateSignature failure:failure];
  };
  
  void (^setSecurityEnv)(NSData *) = ^void (NSData *responseObject) {
    [self setSecurityEnvironment:1 withSuccess:verifyPin2 failure:failure];
  };
  
  [self navigateToFileEEEEWithSuccess:setSecurityEnv failure:failure];
}

- (void)setSecurityEnvironment:(NSUInteger)env withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
    [self.reader transmitCommand:[NSString stringWithFormat:kCommandSetSecurityEnv, env] success:success failure:failure];
}

- (void)verifyCode:(NSString *)code ofType:(CodeType)type withSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
  NSString *command = [NSString stringWithFormat:kCommandVerifyCode, type, code.length, [code toHexString]];
  [self.reader transmitCommand:command success:^(NSData *responseObject) {
    [self checkPinErrors:responseObject success:success failure:failure]();
  } failure:failure];
}

- (void)unblockCode:(CodeType)type withPuk:(NSString *)puk newCode:(NSString *)newCode success:(DataSuccessBlock)success failure:(FailureBlock)failure {
  [self.reader transmitCommand:[NSString stringWithFormat:kCommandResetRetryCounter, type, puk.length + newCode.length, [puk toHexString], [newCode toHexString]] success:^(NSData *responseObject) {
    [self checkPinErrors:responseObject success:success failure:failure]();
  } failure:failure];
}

#pragma mark - private methods

- (void)navigateToFile5044WithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
  void (^select5044)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:kCommandSelectFile5044 success:success failure:failure];
  };
  
  [self navigateToFileEEEEWithSuccess:select5044 failure:failure];
}

- (void)navigateToFileEEEEWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
  void (^selectEEEE)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:kCommandSelectFileEEEE success:success failure:failure];
  };
  
  [self.reader transmitCommand:kCommandSelectFileMaster success:selectEEEE failure:failure];
}

- (VoidBlock) checkPinErrors:(NSData *)response success:(DataSuccessBlock)success failure:(FailureBlock)failure{
  return ^void (void) {
    NSError *error = [self errorForPinActionResponse:response];
    if (error) {
      failure(error);
    } else {
      success(response);
    }
  };
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

- (VoidBlock)readRecord:(NSInteger)record success:(DataSuccessBlock)success failure:(FailureBlock)failure {
  return ^void (void) {
    
    [self.reader transmitCommand:[NSString stringWithFormat:kCommandReadRecord, record] success:^(NSData *responseObject) {
      NSData *trailerData = [responseObject trailingTwoBytes];
      const unsigned char *trailer = [[responseObject trailingTwoBytes] bytes];
      
      if (trailerData.length >= 2 && trailer[0] == 0x90 && trailer[1] == 0x00) {
        success(responseObject);
        
      } else if (trailerData.length >= 1 && trailer[0] == 0x61) {
        NSData *length = [responseObject subdataWithRange:NSMakeRange(responseObject.length - 1, 1)];
        [self.reader transmitCommand:[NSString stringWithFormat:kCommandReadBytes, [length hexString]] success:success failure:failure];
      } else {
        failure([MoppLibError generalError]);
      }
      
    } failure:failure];
  };
}

int maxReadLength = 254;

- (void)readBinaryWithLength:(int)fullLength startingFrom:(int)location readData:(NSData *)data success:(DataSuccessBlock)success failure:(FailureBlock)failure {
  NSString *locationHex = [NSString stringWithFormat:@"%04X", location];
  int lengthToRead = fullLength - location;
  
  if (lengthToRead > maxReadLength) {
    lengthToRead = maxReadLength;
  }
  
  NSString *lengthHex= [NSString stringWithFormat:@"%02X", lengthToRead];
  
  NSString *command = [NSString stringWithFormat:kCommandReadBinary, locationHex, lengthHex];
  [self.reader transmitCommand:command success:^(NSData *responseObject) {
    NSMutableData *newData = [NSMutableData dataWithData:data];
    [newData appendData:[responseObject trailingTwoBytesTrimmed]];
    
    if (location + lengthToRead < fullLength) {
      [self readBinaryWithLength:fullLength startingFrom:location + lengthToRead readData:newData success:success failure:failure];
    } else {
      success(newData);
    }
  } failure:failure];
  
}


- (void)readCertificate:(NSString *)name WithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
  
  void (^selectCertFile)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:[NSString stringWithFormat:kCommandSelectFile, name] success:^(NSData *responseObject) {
      NSString *marker = @"85";
      NSRange markerLocation = [responseObject rangeOfData:[marker toHexData] options:nil range:NSMakeRange(0, responseObject.length)];
      if (markerLocation.location != NSNotFound && markerLocation.location < responseObject.length) {
        
        NSData *bytesData = [responseObject subdataWithRange:NSMakeRange(markerLocation.location + 1, 1)];
        int bytesLength = [[bytesData hexString] hexToInt];
        NSData *lengthData = [responseObject subdataWithRange:NSMakeRange(markerLocation.location + 2, bytesLength)];
        int length = [[lengthData hexString] hexToInt];
        
        [self readBinaryWithLength:length startingFrom:0 readData:[NSData new] success:^(NSData *data) {
            success(data);
        } failure:failure];
      } else {
          failure([MoppLibError generalError]);
      }
    } failure:failure];
  };
  
  [self navigateToFileEEEEWithSuccess:selectCertFile failure:failure];
}

- (void)decryptData:(NSData *)hash withPin1:(NSString *)pin1 useECC:(BOOL)useECC success:(DataSuccessBlock)success failure:(FailureBlock)failure {
    void (^decryptData)(NSData *) = ^void (NSData *responseObject) {
        if (useECC) {
            NSString *commandSuffix;
            long hashLength = hash.length;
            commandSuffix = [NSString stringWithFormat:@"%02lX A6 66 7F 49 63 86 61 %@" ,hashLength +7 , [hash hexString]];
            [self.reader transmitCommand:[NSString stringWithFormat:kCommandFinalDecryption, commandSuffix] success:^(NSData *responseObject) {
                success([responseObject trailingTwoBytesTrimmed]);
            } failure:failure];
            
        } else {
            NSMutableData * data = [NSMutableData dataWithData:hash];
            NSString *commandSuffix;
            long hashLength = hash.length;
            
            if (hashLength>=254) {
                long dataLength = 0;
                while(hashLength - dataLength >= 254){
                    NSData *tempData = [data subdataWithRange:NSMakeRange(dataLength, 254)];
                    commandSuffix = [NSString stringWithFormat:@"%02lX 00 %@" ,tempData.length +1 , [tempData hexString]];
                    [self.reader transmitCommand:[NSString stringWithFormat:kCommandOngoingDecryption, commandSuffix] success:success failure:failure];
                    dataLength +=254;
                }
                commandSuffix = [NSString stringWithFormat:@"%02lX %@" ,hashLength-dataLength  , [[data subdataWithRange:NSMakeRange(dataLength, hashLength-dataLength)] hexString]];
                [self.reader transmitCommand:[NSString stringWithFormat:kCommandFinalDecryption, commandSuffix] success:^(NSData *responseObject) {
                    success([responseObject trailingTwoBytesTrimmed]);
                } failure:failure];
            } else {
                commandSuffix = [NSString stringWithFormat:@"%02lX %@" ,data.length  , [data hexString]];
                [self.reader transmitCommand:[NSString stringWithFormat:kCommandFinalDecryption, commandSuffix] success:^(NSData *responseObject) {
                    success([responseObject trailingTwoBytesTrimmed]);
                } failure:failure];
            }
        }
    };
    
    
    void (^verifyPin1)(NSData *) = ^void (NSData *responseObject) {
        [self verifyCode:pin1 ofType:CodeTypePin1 withSuccess:decryptData failure:failure];
    };
    
    void (^setSecurityEnv)(NSData *) = ^void (NSData *responseObject) {
        [self setSecurityEnvironment:6 withSuccess:verifyPin1 failure:failure];
    };
    
    [self navigateToFileEEEEWithSuccess:setSecurityEnv failure:failure];
    
}

@end

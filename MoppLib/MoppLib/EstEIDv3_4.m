//
//  EstEIDv3_4.m
//  MoppLib
//
//  Created by Katrin Annuk on 28/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "EstEIDv3_4.h"
#import "NSData+Additions.h"
#import "NSString+Additions.h"

@implementation EstEIDv3_4

- (void)readAuthenticationCertificateWithSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure {
  [self readCertificate:kCommandFileAACE WithSuccess:success failure:failure];
}

- (void)readSignatureCertificateWithSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure {
  [self readCertificate:kCommandFileDDCE WithSuccess:success failure:failure];
}

- (void)readPublicDataWithSuccess:(void (^)(MoppLibPersonalData *personalData))success failure:(FailureBlock)failure {
  
  MoppLibPersonalData *personalData = [MoppLibPersonalData new];
  
  void (^readSurname)(void) = [self readRecord:1 success:^(NSData *responseObject) {
    personalData.surname = [responseObject responseString];
    success(personalData);
  } failure:failure];
  
  void (^readFirstNameLine1)(void) = [self readRecord:2 success:^(NSData *responseObject) {
    personalData.firstNameLine1 = [responseObject responseString];
    readSurname();
  } failure:failure];
  
  void (^readFirstNameLine2)(void) = [self readRecord:3 success:^(NSData *responseObject) {
    personalData.firstNameLine2 = [responseObject responseString];
    readFirstNameLine1();
  } failure:failure];
  
  void (^readSex)(void) = [self readRecord:4 success:^(NSData *responseObject) {
    personalData.sex = [responseObject responseString];
    readFirstNameLine2();
  } failure:failure];
  
  void (^readNationality)(void) = [self readRecord:5 success:^(NSData *responseObject) {
    personalData.nationality = [responseObject responseString];
    readSex();
  } failure:failure];
  
  void (^readBirthDate)(void) = [self readRecord:6 success:^(NSData *responseObject) {
    personalData.birthDate = [responseObject responseString];
    readNationality();
  } failure:failure];
  
  void (^readIdCode)(void) = [self readRecord:7 success:^(NSData *responseObject) {
    personalData.personalIdentificationCode = [responseObject responseString];
    readBirthDate();
  } failure:failure];
  
  void (^readDocumentNr)(void) = [self readRecord:8 success:^(NSData *responseObject) {
    personalData.documentNumber = [responseObject responseString];
    readIdCode();
  } failure:failure];
  
  void (^readExpiryDate)(void) = [self readRecord:9 success:^(NSData *responseObject) {
    personalData.expiryDate = [responseObject responseString];
    readDocumentNr();
  } failure:failure];
  
  void (^readPlaceOfBirth)(void) = [self readRecord:10 success:^(NSData *responseObject) {
    personalData.birthPlace = [responseObject responseString];
    readExpiryDate();
  } failure:failure];
  
  void (^readDateIssued)(void) = [self readRecord:11 success:^(NSData *responseObject) {
    personalData.dateIssued = [responseObject responseString];
    readPlaceOfBirth();
  } failure:failure];
  
  void (^readTypeOfPermit)(void) = [self readRecord:12 success:^(NSData *responseObject) {
    personalData.residentPermitType = [responseObject responseString];
    readDateIssued();
  } failure:failure];
  
  void (^readNotes1)(void) = [self readRecord:13 success:^(NSData *responseObject) {
    personalData.notes1 = [responseObject responseString];
    readTypeOfPermit();
  } failure:failure];
  
  void (^readNotes2)(void) = [self readRecord:14 success:^(NSData *responseObject) {
    personalData.notes2 = [responseObject responseString];
    readNotes1();
  } failure:failure];
  
  void (^readNotes3)(void) = [self readRecord:15 success:^(NSData *responseObject) {
    personalData.notes3 = [responseObject responseString];
    readNotes2();
  } failure:failure];
  
  void (^readNotes4)(void) = [self readRecord:16 success:^(NSData *responseObject) {
    personalData.notes4 = [responseObject responseString];
    readNotes3();
  } failure:failure];
  
  void (^select5044)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:kCommandSelectFile5044 success:^(NSData *responseObject) {
      readNotes1();
    } failure:failure];
  };
  
  void (^selectEEEE)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:kCommandSelectFileEEEE success:select5044 failure:failure];
  };
  
  [self.reader transmitCommand:kCommandSelectFileMaster success:selectEEEE failure:failure];
}

- (void)readSecretKeyRecord:(NSInteger)record withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure {
  void (^readRecord)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:[NSString stringWithFormat:kCommandReadRecord, record] success:^(NSData *responseObject) {
      success(responseObject);
      
    } failure:failure];
  };
  
  void (^select0013)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:kCommandSelectFile0013 success:readRecord failure:failure];
  };
  
  void (^selectEEEE)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:kCommandSelectFileEEEE success:select0013 failure:failure];
  };
  
  [self.reader transmitCommand:kCommandSelectFileMaster success:selectEEEE failure:failure];
}

- (void)readCodeCounterRecord:(NSInteger)record withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure {
  void (^readRecord)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:[NSString stringWithFormat:kCommandReadRecord, record] success:success failure:failure];
  };
  
  void (^select0016)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:kCommandSelectFile0016 success:readRecord failure:failure];
  };
  
  [self.reader transmitCommand:kCommandSelectFileMaster success:select0016 failure:failure];
}

- (void)changePin1To:(NSString *)newPin2 verifyCode:(NSString *)code withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure {
  NSString *command = [self codeChangeCommandFor:1 verify:code new:newPin2];
  [self.reader transmitCommand:command success:success failure:failure];
}

- (void)changePin2To:(NSString *)newPin2 verifyCode:(NSString *)code withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure {
  NSString *command = [self codeChangeCommandFor:2 verify:code new:newPin2];
  [self.reader transmitCommand:command success:success failure:failure];
}

- (void)calculateSignature:(NSString *)hash withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure {
  // TODO: support all hash algorithm identifyers
  NSString *algorithmIdentifyer = @"3021300906052B0E03021A05000414";
  NSString *lengthString = [NSString stringWithFormat:@"%i", hash.length + algorithmIdentifyer.length / 2];
  NSString *commandSufix = [NSString stringWithFormat:@"%@ %@ %@", [lengthString toHexString], algorithmIdentifyer, [hash toHexString]];
  [self.reader transmitCommand:[NSString stringWithFormat:kCommandSetSecurityEnv, commandSufix] success:success failure:failure];
}

- (void)setSecurityEnvironment:(NSUInteger)env withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure {
  void (^selectSecureEnv)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:[NSString stringWithFormat:kCommandSetSecurityEnv, env] success:success failure:failure];
  };
  
  void (^selectEEEE)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:kCommandSelectFileEEEE success:selectSecureEnv failure:failure];
  };
  
  [self.reader transmitCommand:kCommandSelectFileMaster success:selectEEEE failure:failure];
}

- (void)verifyPin1:(NSString *)pin1 withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure {
  NSString *command = [self verifyCommandFor:1 verify:pin1];
  [self.reader transmitCommand:command success:success failure:failure];
}

- (void)verifyPin2:(NSString *)pin2 withSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure {
  NSString *command = [self verifyCommandFor:2 verify:pin2];
  [self.reader transmitCommand:command success:success failure:failure];
}

#pragma mark - private methods

- (NSString *)codeChangeCommandFor:(NSUInteger)code verify:(NSString *)verifyValue new:(NSString *)newValue {
  NSString *recordString = [NSString stringWithFormat:@"%i", code];
  NSString *lengthString = [NSString stringWithFormat:@"%i", newValue.length + verifyValue.length];
  NSString *commandSufix = [NSString stringWithFormat:@"%@ %@ %@ %@", [recordString toHexString], [lengthString toHexString], [verifyValue toHexString], [newValue toHexString]];
  return [NSString stringWithFormat:kCommandChangeReferenceData, commandSufix];
}

- (NSString *)verifyCommandFor:(NSUInteger)code verify:(NSString *)verifyValue {
  NSString *codeString = [NSString stringWithFormat:@"%i", code];
  NSString *lengthString = [NSString stringWithFormat:@"%i", verifyValue.length];
  NSString *commandSufix = [NSString stringWithFormat:@"%@ %@ %@", [codeString toHexString], [lengthString toHexString], [verifyValue toHexString]];
  return [NSString stringWithFormat:kCommandVerifyCode, commandSufix];
}

- (void (^)(void))readRecord:(NSInteger)record success:(DataSuccessBlock)success failure:(FailureBlock)failure {
  return ^void (void) {
    
    [self.reader transmitCommand:[NSString stringWithFormat:kCommandReadRecord, record] success:^(NSData *responseObject) {
      const unsigned char *trailer = [responseObject responseTrailer];
      
      if (trailer[0] == 0x90 && trailer[1] == 0x00) {
        success(responseObject);
        
      } else if (trailer[0] == 0x61) {
        NSData *length = [responseObject subdataWithRange:NSMakeRange(responseObject.length - 1, 1)];
        [self.reader transmitCommand:[NSString stringWithFormat:kCommandReadBytes, [length toHexString]] success:success failure:failure];
      }
      
    } failure:failure];
  };
}

int maxReadLength = 254;

- (void)readBinaryWithLength:(int)fullLength startingFrom:(int)location readData:(NSData *)data success:(void (^)(NSData *personalData))success failure:(FailureBlock)failure {
  NSString *locationHex = [NSString stringWithFormat:@"%04X", location];
  int lengthToRead = fullLength - location;
  
  if (lengthToRead > maxReadLength) {
    lengthToRead = maxReadLength;
  }
  
  NSString *lengthHex= [NSString stringWithFormat:@"%02X", lengthToRead];
  
  NSString *command = [NSString stringWithFormat:kCommandReadBinary, locationHex, lengthHex];
  [self.reader transmitCommand:command success:^(NSData *responseObject) {
    NSMutableData *newData = [NSMutableData dataWithData:data];
    [newData appendData:[responseObject trimmedData]];
    
    if (location + lengthToRead < fullLength) {
      [self readBinaryWithLength:fullLength startingFrom:location + lengthToRead readData:newData success:success failure:failure];
    } else {
      success(newData);
    }
  } failure:failure];
  
}


- (void)readCertificate:(NSString *)name WithSuccess:(void (^)(NSData *data))success failure:(FailureBlock)failure {
  
  void (^selectCertFile)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:[NSString stringWithFormat:kCommandSelectFile, name] success:^(NSData *responseObject) {
      NSString *marker = @"85";
      NSRange markerLocation = [responseObject rangeOfData:[marker toHexData] options:nil range:NSMakeRange(0, responseObject.length)];
      if (markerLocation.location != NSNotFound) {
        
        NSData *bytesData = [responseObject subdataWithRange:NSMakeRange(markerLocation.location + 1, 1)];
        int *bytesLength = [[bytesData toHexString] hexToInt];
        NSData *lengthData = [responseObject subdataWithRange:NSMakeRange(markerLocation.location + 2, bytesLength)];
        int *length = [[lengthData toHexString] hexToInt];
        
        [self readBinaryWithLength:length startingFrom:0 readData:[NSData new] success:^(NSData *data) {
          success(data);
        } failure:failure];
      }
    } failure:failure];
  };
  
  void (^selectEEEE)(NSData *) = ^void (NSData *responseObject) {
    [self.reader transmitCommand:kCommandSelectFileEEEE success:selectCertFile failure:failure];
  };
  
  [self.reader transmitCommand:kCommandSelectFileMaster success:selectEEEE failure:failure];
}


@end

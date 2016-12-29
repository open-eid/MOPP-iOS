//
//  EstEIDv3_4.m
//  MoppLib
//
//  Created by Katrin Annuk on 28/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "EstEIDv3_4.h"

@implementation EstEIDv3_4

- (void)cardReader:(id<CardReaderWrapper>)reader readPublicDataWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure {
  
  void (^readSurname)(NSData *) = [self reader:reader readRecord:1 success:success failure:failure];
  void (^readFirstNameLine1)(NSData *) = [self reader:reader readRecord:2 success:readSurname failure:failure];
  void (^readFirstNameLine2)(NSData *) = [self reader:reader readRecord:3 success:readFirstNameLine1 failure:failure];
  void (^readSex)(NSData *) = [self reader:reader readRecord:4 success:readFirstNameLine2 failure:failure];
  void (^readNationality)(NSData *) = [self reader:reader readRecord:5 success:readSex failure:failure];
  void (^readBirthDate)(NSData *) = [self reader:reader readRecord:6 success:readNationality failure:failure];
  void (^readIdCode)(NSData *) = [self reader:reader readRecord:7 success:readBirthDate failure:failure];
  void (^readDocumentNr)(NSData *) = [self reader:reader readRecord:8 success:readIdCode failure:failure];
  void (^readExpiryDate)(NSData *) = [self reader:reader readRecord:9 success:readDocumentNr failure:failure];
  void (^readPlaceOfBirth)(NSData *) = [self reader:reader readRecord:10 success:readExpiryDate failure:failure];
  void (^readDateIssued)(NSData *) = [self reader:reader readRecord:11 success:readPlaceOfBirth failure:failure];
  void (^readTypeOfPermit)(NSData *) = [self reader:reader readRecord:12 success:readDateIssued failure:failure];
  void (^readNotes1)(NSData *) = [self reader:reader readRecord:13 success:readTypeOfPermit failure:failure];
  void (^readNotes2)(NSData *) = [self reader:reader readRecord:14 success:readNotes1 failure:failure];
  void (^readNotes3)(NSData *) = [self reader:reader readRecord:15 success:readNotes2 failure:failure];
  void (^readNotes4)(NSData *) = [self reader:reader readRecord:16 success:readNotes3 failure:failure];
  
  void (^select5044)(NSData *) = ^void (NSData *responseObject) {
    [reader transmitCommand:kCommandSelectFile5044 success:readNotes1 failure:failure];
  };
  
  void (^selectEEEE)(NSData *) = ^void (NSData *responseObject) {
    [reader transmitCommand:kCommandSelectFileEEEE success:select5044 failure:failure];
  };
  
  [reader transmitCommand:kCommandSelectFileMaster success:selectEEEE failure:failure];
  
}

- (void (^)(NSData *))reader:(id<CardReaderWrapper>)reader readRecord:(NSInteger)record success:(DataSuccessBlock)success failure:(FailureBlock)failure {
  return ^void (NSData *responseObject) {

    [reader transmitCommand:[NSString stringWithFormat:kCommandReadRecord, record] success:^(NSData *responseObject) {
      const unsigned char *trailer = [responseObject responseTrailer];
      
      if (trailer[0] == 0x90 && trailer[1] == 0x00) {
        success(responseObject);
        
      } else if (trailer[0] == 0x61) {
        NSData *length = [responseObject subdataWithRange:NSMakeRange(responseObject.length - 1, 1)];
        [reader transmitCommand:[NSString stringWithFormat:kCommandReadBytes, [length toHexString]] success:success failure:failure];
      }
      
    } failure:failure];
  };
}
@end

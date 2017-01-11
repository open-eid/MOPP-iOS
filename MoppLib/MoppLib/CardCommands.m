//
//  CardCommands.m
//  MoppLib
//
//  Created by Katrin Annuk on 27/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "CardCommands.h"

// Navigation commands
NSString *const kCommandSelectFileMaster = @"00 A4 00 0C";
NSString *const kCommandSelectFileEEEE = @"00 A4 01 0C 02 EE EE";
NSString *const kCommandSelectFile0016 = @"00 A4 02 0C 02 00 16";
NSString *const kCommandSelectFile5044 = @"00 A4 02 04 02 50 44";
NSString *const kCommandSelectFile = @"00 A4 02 04 02 %@";
NSString *const kCommandSelectFile0013 = @"00 A4 02 04 02 00 13";
NSString *const kCommandFileDDCE = @"DD CE";
NSString *const kCommandFileAACE = @"AA CE";

NSString *const kCommandReadRecord = @"00 B2 %02X 04 00";
NSString *const kCommandReadBytes = @"00 C0 00 00 %@";
NSString *const kCommandGetCardVersion = @"00 CA 01 00 00";
NSString *const kCommandReadBinary = @"00 B0 %@ %@";
NSString *const kCommandChangeReferenceData = @"00 24 00 %02X %02X %@";
NSString *const kCommandSetSecurityEnv = @"00 22 F3 %02X";
NSString *const kCommandVerifyCode = @"00 20 00 %02X %02X %@";
NSString *const kCommandCalculateSignature = @"00 2A 9E 9A %@";
NSString *const kCommandResetRetryCounter = @"00 2C 00 %02X %02X %@ %@";


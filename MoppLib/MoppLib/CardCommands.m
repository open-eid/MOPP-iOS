//
//  CardCommands.m
//  MoppLib
//
//  Created by Katrin Annuk on 27/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "CardCommands.h"

NSString *const kCommandSelectFileMaster = @"00 A4 00 0C";
NSString *const kCommandSelectFileEEEE = @"00 A4 01 0C 02 EE EE";
NSString *const kCommandSelectFile5044 = @"00 A4 02 04 02 50 44";
NSString *const kCommandSelectFileAACE = @"00 A4 02 04 02 AA CE";
NSString *const kCommandSelectFileDDCE = @"00 A4 02 04 02 DD CE";
NSString *const kCommandSelectFile0013 = @"00 A4 02 04 02 00 13";
NSString *const kCommandReadRecord = @"00 B2 %02X 04 00";
NSString *const kCommandReadBytes = @"00 C0 00 00 %@";
NSString *const kCommandGetCardVersion = @"00 CA 01 00 00";
NSString *const kCommandReadBinary = @"00 B0 %@ %@";




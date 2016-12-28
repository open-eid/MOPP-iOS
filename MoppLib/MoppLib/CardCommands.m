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
NSString *const kCommandReadRecord = @"00 B2 01 04";
NSString *const kCommandReadBytes = @"00 C0 00 00 %@";

//
//  CardCommands.m
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
NSString *const kCommandOngoingDecryption = @"10 2A 80 86 %@";
NSString *const kCommandFinalDecryption = @"00 2A 80 86 %@";
NSString *const kCommandResetRetryCounter = @"00 2C 00 %02X %02X %@ %@";

NSString *const kAlgorythmIdentifyerSHA1 = @"3021300906052B0E03021A05000414";
NSString *const kAlgorythmIdentifyerSHA224 = @"302D300D06096086480165030402040500041C";
NSString *const kAlgorythmIdentifyerSHA256 = @"3031300D060960864801650304020105000420";
NSString *const kAlgorythmIdentifyerSHA384 = @"3041300D060960864801650304020205000430";
NSString *const kAlgorythmIdentifyerSHA512 = @"3051300D060960864801650304020305000440";

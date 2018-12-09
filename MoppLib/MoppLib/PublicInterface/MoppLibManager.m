//
//  MoppLibManager.m
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

#import "MoppLibManager.h"
#import "MoppLibDigidocManager.h"

@implementation MoppLibManager

+ (MoppLibManager *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)setupWithSuccess:(VoidBlock)success andFailure:(FailureBlock)failure usingTestDigiDocService:(BOOL)useTestDDS andTSUrl:(NSString *)tsUrl {
  [[MoppLibDigidocManager sharedInstance] setupWithSuccess:success andFailure:failure usingTestDigiDocService:useTestDDS andTSUrl:tsUrl];
}

- (NSString *)moppLibVersion {
  return [[MoppLibDigidocManager sharedInstance] getMoppLibVersion];
}

- (NSString *)libdigidocppVersion {
    return [[MoppLibDigidocManager sharedInstance] digidocVersion];
}

+ (NSString *)defaultTSUrl {
    return [MoppLibDigidocManager defaultTSUrl];
}

@end

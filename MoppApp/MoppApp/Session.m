//
//  Session.m
//  MoppApp
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

#import "Session.h"
#import "DefaultsHelper.h"
#import "Constants.h"

@implementation Session

+ (Session *)sharedInstance {
  static dispatch_once_t once;
  static id sharedInstance;
  dispatch_once(&once, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)setup {
  NSString *newContainerFormat = [DefaultsHelper getNewContainerFormat];
  if (!newContainerFormat) {
    [DefaultsHelper setNewContainerFormat:ContainerFormatBdoc];
  }


}

- (void)createMobileSignatureWithContainer:(NSString *)containerPath idCode:(NSString *)idCode language:(NSString *)language phoneNumber:(NSString *)phoneNumber {
  [[MoppLibContainerActions sharedInstance] getContainerWithPath:containerPath success:^(MoppLibContainer *initialContainer) {
    [[MoppLibService sharedInstance] mobileCreateSignatureWithContainer:containerPath idCode:idCode language:language phoneNumber:phoneNumber withCompletion:^(MoppLibMobileCreateSignatureResponse *response) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kCreateSignatureNotificationName object:nil userInfo:@{kCreateSignatureResponseKey : response}];
    } andStatus:^(MoppLibContainer *container, NSError *error, NSString *status) {
      if (error.domain) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kErrorNotificationName object:nil userInfo:@{kErrorKey : error}];
      } else if (container) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSignatureAddedToContainerNotificationName object:nil userInfo:@{kNewContainerKey : container, kOldContainerKey : initialContainer}];
      }
    }];
  } failure:^(NSError *error) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kErrorNotificationName object:nil userInfo:@{kErrorKey : error}];
    return;
  }];
  
}

@end

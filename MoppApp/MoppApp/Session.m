//
//  Session.m
//  MoppApp
//
//  Created by Ants Käär on 19.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "Session.h"
#import "DefaultsHelper.h"

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

- (void)createMobileSignatureWithContainer:(MoppLibContainer *)initialContainer idCode:(NSString *)idCode language:(NSString *)language phoneNumber:(NSString *)phoneNumber {
  [[MoppLibService sharedInstance] mobileCreateSignatureWithContainer:initialContainer idCode:idCode language:language phoneNumber:phoneNumber withCompletion:^(NSObject *responseObject) {
    MoppLibMobileCreateSignatureResponse *respone = (MoppLibMobileCreateSignatureResponse *)responseObject;
    [[NSNotificationCenter defaultCenter] postNotificationName:kCreateSignatureNotificationName object:nil userInfo:@{kCreateSignatureResponseKey : respone}];
  } andStatus:^(MoppLibContainer *container, NSError *error, NSString *status) {
    if (error.domain) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kErrorNotificationName object:nil userInfo:@{kErrorKey : error}];
    } else if (container) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kSignatureAddedToContainerNotificationName object:nil userInfo:@{kNewContainerKey : container, kOldContainerKey : initialContainer}];
    }
  }];
}

@end

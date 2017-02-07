//
//  MoppLibService.m
//  MoppLib
//
//  Created by Olev Abel on 2/3/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "MoppLibService.h"
#import "MoppLibNetworkManager.h"
#import "MoppLibConstants.h"
#import "MoppLibMobileCreateSignatureResponse.h"
#import "MoppLibGetMobileCreateSigntaureStatusResponse.h"
#import "MoppLibDigidocManager.h"

static NSInteger *kInitialStatusRequestDelay = 10;
static NSInteger *kSubsequentStatusRequestDelay = 5;

@interface MoppLibService ()

@property (nonatomic, strong) MoppLibContainer *currentContainer;

@end

@implementation MoppLibService

+ (MoppLibService *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibService *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)mobileCreateSignatureWithContainer:(MoppLibContainer *)container idCode:(NSString *)idCode language:(NSString *)language phoneNumber:(NSString *)phoneNumber {
  self.currentContainer = container;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
  [[MoppLibNetworkManager sharedInstance] mobileCreateSignatureWithContainer:container language:language idCode:idCode phoneNo:phoneNumber withSuccess:^(NSObject *responseObject) {
    MoppLibMobileCreateSignatureResponse *response = (MoppLibMobileCreateSignatureResponse *)responseObject;
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:kCreateSignatureNotificationName object:nil userInfo:@{kCreateSignatureResponseKey : responseObject}];
    });
    [self getMobileCreateSignatureWithSessCode:[NSString stringWithFormat:@"%d", response.sessCode]];
  } andFailure:^(NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:kErrorNotificationName object:nil userInfo:@{kErrorKey : error}];
    });
  }];
  });
  
}

- (void)getMobileCreateSignatureWithSessCode:(NSString *)sessCode {
  [[MoppLibNetworkManager sharedInstance] getMobileCreateSignatureStatusWithSesscode:sessCode withSuccess:^(NSObject *responseObject) {
    MoppLibGetMobileCreateSigntaureStatusResponse *response = (MoppLibGetMobileCreateSigntaureStatusResponse *)responseObject;
    if ([response.status isEqualToString:@"OUTSTANDING_TRANSACTION"]) {
      sleep(kSubsequentStatusRequestDelay);
      [self getMobileCreateSignatureWithSessCode:sessCode];
    } else if ([response.status isEqualToString:@"SIGNATURE"]) {
      [[MoppLibDigidocManager sharedInstance] addMobileIDSignatureToContainer:self.currentContainer signature:response.signature];
      [[NSNotificationCenter defaultCenter] postNotificationName:kCreateSignatureStatusNotificationName object:nil userInfo:@{kGetCreateSignatureStatusKey : responseObject}];
    } else {
      NSLog(@"FAILURE with status: %@", response.status);
    }
  } andFailure:^(NSError *error) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kErrorNotificationName object:nil userInfo:@{kErrorKey : error}];
  }];
}

@end
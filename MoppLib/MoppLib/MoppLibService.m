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
#import "MoppLibGetMobileCreateSignatureStatusResponse.h"
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
  __weak typeof(self) weakSelf = self;
  self.currentContainer = container;
  [[MoppLibNetworkManager sharedInstance] mobileCreateSignatureWithContainer:container language:language idCode:idCode phoneNo:phoneNumber withSuccess:^(NSObject *responseObject) {
    MoppLibMobileCreateSignatureResponse *response = (MoppLibMobileCreateSignatureResponse *)responseObject;
    dispatch_async(dispatch_get_main_queue(), ^{
      self.willPollForSignatureResponse = YES;
      [[NSNotificationCenter defaultCenter] postNotificationName:kCreateSignatureNotificationName object:nil userInfo:@{kCreateSignatureResponseKey : responseObject}];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [self getMobileCreateSignatureWithSessCode:[NSString stringWithFormat:@"%d", response.sessCode]];
    });
  } andFailure:^(NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:kErrorNotificationName object:nil userInfo:@{kErrorKey : error}];
    });
  }];
  
}

- (void)getMobileCreateSignatureWithSessCode:(NSString *)sessCode {
  if (self.willPollForSignatureResponse) {
    [[MoppLibNetworkManager sharedInstance] getMobileCreateSignatureStatusWithSesscode:sessCode withSuccess:^(NSObject *responseObject) {
      MoppLibGetMobileCreateSignatureStatusResponse *response = (MoppLibGetMobileCreateSignatureStatusResponse *)responseObject;
      if ([response.status isEqualToString:@"OUTSTANDING_TRANSACTION"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          MLLog(@"Session started");
          [self getMobileCreateSignatureWithSessCode:sessCode];
        });
      } else if ([response.status isEqualToString:@"SIGNATURE"]) {
        [[MoppLibDigidocManager sharedInstance] addMobileIDSignatureToContainer:self.currentContainer signature:response.signature success:^(MoppLibContainer *container) {
          dispatch_async(dispatch_get_main_queue(), ^{
            MLLog(@"Notification sent out");
            [[NSNotificationCenter defaultCenter] postNotificationName:kSignatureAddedToContainerNotificationName object:nil userInfo:@{kContainerKey : container}];
          });
        } andFailure:^(NSError *error) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kErrorNotificationName object:nil ];
          });
        }];
        
      } else {
#warning TODO - add all posible statuses if necessary
        MLLog(@"FAILURE with status: %@", response.status);
        dispatch_async(dispatch_get_main_queue(), ^{
          [[NSNotificationCenter defaultCenter] postNotificationName:kErrorNotificationName object:nil ];
        });
      }
    } andFailure:^(NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kErrorNotificationName object:nil userInfo:@{kErrorKey : error}];
      });
    }];
  }
}

- (void)cancelMobileSignatureStatusPolling {
  self.willPollForSignatureResponse = NO;
}
@end

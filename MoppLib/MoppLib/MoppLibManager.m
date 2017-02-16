//
//  MoppLibManager.m
//  MoppLib
//
//  Created by Katrin Annuk on 03/02/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

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

- (void)setupWithSuccess:(EmptySuccessBlock)success andFailure:(FailureBlock)failure {
  [[MoppLibDigidocManager sharedInstance] setupWithSuccess:success andFailure:failure];
}

- (NSString *)getMoppLibVersion {
  return [[MoppLibDigidocManager sharedInstance] getMoppLibVersion];
}
@end

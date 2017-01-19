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

@end

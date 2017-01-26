//
//  DepencenyWrapper.m
//  MoppApp
//
//  Created by Olev Abel on 1/26/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "DependencyWrapper.h"

@implementation DependencyWrapper

- (id)initWithDependencyName:(NSString *)dependencyName licenseName:(NSString *)licenseName licenseLink:(NSString *)licenseLink {
  self = [super init];
  if (self) {
    self.dependencyName = dependencyName;
    self.licenseName = licenseName;
    self.licenseLink = licenseLink;
  }
  return self;
}
@end

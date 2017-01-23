//
//  DefaultsHelper.m
//  MoppApp
//
//  Created by Ants Käär on 19.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "DefaultsHelper.h"

NSString *const ContainerFormatBdoc = @"bdoc";
NSString *const ContainerFormatAsice = @"asice";

// Keys
NSString *const kNewContainerFormatKey = @"kNewContainerFormatKey";

@implementation DefaultsHelper

// New container format
+ (void)setNewContainerFormat:(NSString *)newContainerFormat {
  [[NSUserDefaults standardUserDefaults] setObject:newContainerFormat forKey:kNewContainerFormatKey];
}

+ (NSString *)getNewContainerFormat {
  NSString *newContainerFormat = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:kNewContainerFormatKey];
  return newContainerFormat;
}

@end

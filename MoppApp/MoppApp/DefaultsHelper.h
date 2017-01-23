//
//  DefaultsHelper.h
//  MoppApp
//
//  Created by Ants Käär on 19.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const ContainerFormatBdoc;
extern NSString *const ContainerFormatAsice;

@interface DefaultsHelper : NSObject

// New container format
+ (void)setNewContainerFormat:(NSString *)newContainerFormat;
+ (NSString *)getNewContainerFormat;

@end

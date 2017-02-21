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
extern NSString *const ContainerFormatDdoc;

@interface DefaultsHelper : NSObject

// New container format
+ (void)setNewContainerFormat:(NSString *)newContainerFormat;
+ (NSString *)getNewContainerFormat;
+ (void)setPhoneNumber:(NSString *)phoneNumber;
+ (NSString *)getPhoneNumber;
+ (void)setIDCode:(NSString *)idCode;
+ (NSString *)getIDCode;
+ (void)setSmartID:(NSString*)account;
+ (NSString *)getSmartID;
@end

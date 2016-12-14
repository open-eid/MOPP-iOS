//
//  CardLib.h
//  iEstEidUtil
//
//  Created by Raul Metsma on 21.05.12.
//  Copyright (c) 2012 SK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PBAccessory.h"

@protocol CardLibDelegate

@optional

- (void)message:(NSString*)msg;
- (void)atr:(NSString*)atr;

@end

@interface CardLib : NSObject <PBAccessoryDelegate>

- (id)initWithDelegate:(id<CardLibDelegate>) delegate;
- (bool)changePin1:(NSString*)oldpin newpin:(NSString*)pin;
- (bool)changePin2:(NSString*)oldpin newpin:(NSString*)pin;
- (bool)changePuk:(NSString*)oldpin newpin:(NSString*)pin;

@property(nonatomic,assign) id<CardLibDelegate> delegate;

@property(nonatomic,readonly) NSString *atr;
@property(nonatomic,readonly) NSArray *personalfile;
@property(nonatomic,readonly) NSData *authCert, *signCert;
@property(nonatomic,readonly) NSUInteger authUsage, authLeft, signUsage, signLeft;

@end

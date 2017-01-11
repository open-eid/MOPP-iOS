//
//  MoppLibPinActions.h
//  MoppLib
//
//  Created by Katrin Annuk on 09/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MoppLibPinActions : NSObject

+ (void)changePin1To:(NSNumber *)newPin1 withOldPin1:(NSNumber *)oldPin1 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure;
+ (void)changePin1To:(NSNumber *)newPin1 withPuk:(NSNumber *)puk viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure;
+ (void)changePin2To:(NSNumber *)newPin2 withOldPin2:(NSNumber *)oldPin2 viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure;
+ (void)changePin2To:(NSNumber *)newPin2 withPuk:(NSNumber *)puk viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure;

@end

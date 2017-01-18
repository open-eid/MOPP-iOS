//
//  MoppLibPinActions+Tests.h
//  MoppLib
//
//  Created by Katrin Annuk on 17/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <MoppLib/MoppLib.h>
#import "CardActionsManager.h"

@interface MoppLibPinActions (Tests)
+ (void)verifyType:(CodeType)type pin:(NSString *)pin andVerificationCode:(NSString *)verificationCode viewController:(UIViewController *)controller success:(void(^)(void))success failure:(void(^)(NSError *))failure;

@end

//
//  MoppLibManager.h
//  MoppLib
//
//  Created by Katrin Annuk on 03/02/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibCardActions.h"
#import "MoppLibConstants.h"

@interface MoppLibManager : NSObject

+ (MoppLibManager *)sharedInstance;
- (void)setupWithSuccess:(EmptySuccessBlock)success andFailure:(FailureBlock)failure;
@end

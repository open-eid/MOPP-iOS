//
//  MoppLibManager.h
//  MoppLib
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibContainer.h"
#import "MoppLibConstants.h"

@interface MoppLibManager : NSObject

+ (MoppLibManager *)sharedInstance;

- (void)setupWithSuccess:(EmptySuccessBlock)success andFailure:(FailureBlock)failure;
- (void)getContainerWithPath:(NSString *)containerPath withSuccess:(ObjectSuccessBlock)success andFailure:(FailureBlock)failure;

@end

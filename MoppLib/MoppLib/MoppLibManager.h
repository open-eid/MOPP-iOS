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

/**
 * Prepares library for operations with containers. Setup must be completed before any container action is carried out. It is recommended, that you initiate setup at earliest opportunity.
 *
 * @param success       Block to be called on successful completion of action.
 * @param failure       Block to be called when action fails. Includes error.
 */
- (void)setupWithSuccess:(EmptySuccessBlock)success andFailure:(FailureBlock)failure;

- (NSString *)getMoppLibVersion;
@end

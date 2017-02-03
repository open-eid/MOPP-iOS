//
//  MoppLibNetworkManager.h
//  MoppLib
//
//  Created by Olev Abel on 2/2/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibSOAPManager.h"
#import "MoppLibConstants.h"

@interface MoppLibNetworkManager : NSObject<NSURLSessionDelegate>

+ (MoppLibNetworkManager *)sharedInstance;
- (void)mobileCreateSignatureWithContainer:(MoppLibContainer *)container
                               language:(NSString *)nationality
                                    idCode:(NSString *)idCode
                                   phoneNo:(NSString *)phoneNo
                               withSuccess:(ObjectSuccessBlock)success
                                andFailure:(FailureBlock)failure;

@end

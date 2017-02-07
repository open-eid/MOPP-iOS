//
//  MOPPSOAPManager.h
//  MoppLib
//
//  Created by Olev Abel on 1/27/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibContainer.h"
#import "MoppLibPersonalData.h"
#import "MoppLibConstants.h"
#import "MoppLibNetworkManager.h"


@interface MoppLibSOAPManager : NSObject

+ (MoppLibSOAPManager *)sharedInstance;

- (NSString *)mobileCreateSignatureWithContainer:(MoppLibContainer *)container
                                        language:(NSString *)language
                                          idCode:(NSString *)idCode
                                         phoneNo:(NSString *)phoneNo;

- (NSString *)getMobileCreateSignatureStatusWithSessCode:(NSString *)sessCode;

- (void)processResultWithData:(NSData *)data
                       method:(MoppLibNetworkRequestMethod)method
                  withSuccess:(ObjectSuccessBlock)success
                   andFailure:(FailureBlock)failure;
@end

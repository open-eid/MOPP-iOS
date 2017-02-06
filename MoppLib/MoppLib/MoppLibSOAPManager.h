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


@interface MoppLibSOAPManager : NSObject

+ (MoppLibSOAPManager *)sharedInstance;

- (NSString *)mobileCreateSignatureWithContainer:(MoppLibContainer *)container
                                        language:(NSString *)language
                                          idCode:(NSString *)idCode
                                         phoneNo:(NSString *)phoneNo;

- (void)parseMobileCreateSignatureResultWithResponseData:(NSData *)data
                                             withSuccess:(ObjectSuccessBlock)success
                                              andFailure:(FailureBlock)failure;

- (NSString *)getMobileCreateSignatureStatusWithSessCode:(NSString *)sessCode;

- (void)parseGetMobileCreateSignatureResponseWithData:(NSData *)data
                                          withSuccess:(ObjectSuccessBlock)success
                                           andFailure:(FailureBlock)failure;
@end

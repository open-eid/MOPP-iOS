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

- (NSString *)mobileCreateSignatureWithContainer:(MoppLibContainer *)container nationality:(NSString *)nationality idCode:(NSString *)idCode phoneNo:(NSString *)phoneNo;

- (void)parseMobileCreateSignatureResultWithResponseData:(NSData *)data withSuccess:(ObjectSuccessBlock)success andFailure:(FailureBlock)failure;

@end

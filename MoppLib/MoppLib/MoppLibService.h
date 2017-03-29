//
//  MoppLibService.h
//  MoppLib
//
//  Created by Olev Abel on 2/3/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibContainer.h"
#import "MoppLibConstants.h"

@interface MoppLibService : NSObject

@property (nonatomic) BOOL willPollForSignatureResponse;



+ (MoppLibService *)sharedInstance;

- (void)mobileCreateSignatureWithContainer:(NSString *)containerPath idCode:(NSString *)idCode language:(NSString *)language phoneNumber:(NSString *)phoneNumber withCompletion:(MobileCreateSignatureResponseBlock)success andStatus:(SignatureStatusBlock)failure;

- (void)cancelMobileSignatureStatusPolling;
@end

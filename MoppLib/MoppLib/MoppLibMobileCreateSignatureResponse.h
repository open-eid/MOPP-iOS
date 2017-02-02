//
//  MoppLibMobileCreateSignatureResponse.h
//  MoppLib
//
//  Created by Olev Abel on 2/2/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibSOAPManager.h"


@interface MoppLibMobileCreateSignatureResponse : NSObject
@property (nonatomic, strong) NSString *challengeId;
@property (nonatomic) NSInteger sessCode;
@property (nonatomic, strong) NSString *status;
@end

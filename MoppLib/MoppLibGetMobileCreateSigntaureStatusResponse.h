//
//  MoppLibGetMobileCreateSigntaureStatusResponse.h
//  MoppLib
//
//  Created by Olev Abel on 2/3/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MoppLibGetMobileCreateSigntaureStatusResponse : NSObject

@property (nonatomic) NSInteger sessCode;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *signature;
@end

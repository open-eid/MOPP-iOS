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


@interface MoppSOAPManager : NSObject

- (void)mobileCreateSignatureWithContainer:(MoppLibContainer *)container persionalData:(MoppLibPersonalData *)personalData;
@end

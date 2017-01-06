//
//  MoppLibManager.h
//  MoppLib
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibContainer.h"

@interface MoppLibManager : NSObject

+ (MoppLibManager *)sharedInstance;

- (MoppLibContainer *)getContainerWithPath:(NSString *)containerPath;

@end

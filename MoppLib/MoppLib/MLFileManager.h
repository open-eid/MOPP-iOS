//
//  MLFileManager.h
//  MoppLib
//
//  Created by Ants Käär on 17.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLFileManager : NSObject

+ (MLFileManager *)sharedInstance;

- (NSArray *)getContainers;
- (NSDictionary *)fileAttributes:(NSString *)filePath;

@end

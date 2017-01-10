//
//  MLDateFormatter.h
//  MoppLib
//
//  Created by Ants Käär on 09.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLDateFormatter : NSObject

+ (MLDateFormatter *)sharedInstance;

// 2013-12-10T09:11:39Z
- (NSDate *)YYYYMMddTHHmmssZToDate:(NSString *)string;

@end

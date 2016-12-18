//
//  X509Wrapper.h
//  MOPP POC
//
//  Created by Katrin Annuk on 16/12/16.
//  Copyright © 2016 Katrin Annuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface X509Wrapper : NSObject
+ (NSString *)getIssuerName:(NSData *)data;
+ (NSDate *)getExpiryDate:(NSData *)data;
@end

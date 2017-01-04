//
//  NSDate+Additions.h
//  MoppApp
//
//  Created by Katrin Annuk on 04/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Additions)

- (NSString *)expiryDateString;
+ (NSDateFormatter *)formatter;
@end

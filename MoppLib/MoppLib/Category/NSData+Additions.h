//
//  NSData+Additions.h
//  MoppLib
//
//  Created by Katrin Annuk on 22/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Additions)
- (NSString *)toHexString;
- (NSData *)responseTrailerData;
- (NSString *)responseString;
- (NSData *)trimmedData;
@end

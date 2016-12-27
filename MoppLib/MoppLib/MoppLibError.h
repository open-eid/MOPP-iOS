//
//  MoppLibError.h
//  MoppLib
//
//  Created by Katrin Annuk on 23/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
  
 moppLibReaderNotFoundError = 10001
  
} MoppLibErrorCode;


@interface MoppLibError : NSObject

+ (NSError *)readerNotFoundError;
@end

//
//  MoppLibError.m
//  MoppLib
//
//  Created by Katrin Annuk on 23/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import "MoppLibError.h"


@implementation MoppLibError

+ (NSError *)readerNotFoundError {
  NSError *newError = [[NSError alloc] initWithDomain:nil code:moppLibReaderNotFoundError userInfo:nil];
  return newError;
}
@end

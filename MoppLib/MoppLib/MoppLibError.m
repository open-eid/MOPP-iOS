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
  return [self error:moppLibReaderNotFoundError];
}

+ (NSError *)cardNotFoundError {
  return [self error:moppLibCardNotFoundError];
}

+ (NSError *)error:(NSUInteger)errorCode {
  NSError *newError = [[NSError alloc] initWithDomain:@"MoppLib" code:errorCode userInfo:nil];
  return newError;
}

@end

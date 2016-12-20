//
//  NSString+Additions.m
//  MOPP POC
//
//  Created by Katrin Annuk on 19/12/16.
//  Copyright © 2016 Katrin Annuk. All rights reserved.
//

#import "NSString+Additions.h"
#include <sys/xattr.h>
#import <CommonCrypto/CommonCrypto.h>

@implementation NSString (Additions)

- (NSString*)sha1 {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (int)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return output;
}
@end

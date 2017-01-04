//
//  MoppLibCertificate.h
//  MoppLib
//
//  Created by Katrin Annuk on 04/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#include <Foundation/Foundation.h>
#import "MoppLibCertData.h"

@interface MoppLibCertificate : NSObject
+ (void)certData:(MoppLibCertData *)certData updateWithData:(const unsigned char *)data length:(size_t)length;
@end

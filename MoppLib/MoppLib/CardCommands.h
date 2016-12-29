//
//  CardCommands.h
//  MoppLib
//
//  Created by Katrin Annuk on 27/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CardReaderWrapper.h"
#import "NSString+Additions.h"
#import "NSData+Additions.h"

extern NSString *const kCommandSelectFileMaster;
extern NSString *const kCommandSelectFileEEEE;
extern NSString *const kCommandSelectFile5044;
extern NSString *const kCommandReadRecord;
extern NSString *const kCommandReadBytes;
extern NSString *const kCommandGetCardVersion;


@protocol CardCommands <NSObject>

- (void)cardReader:(id<CardReaderWrapper>)reader readPublicDataWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure;
@end

//
//  MoppLibManager.h
//  MoppLib
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibContainer.h"
#import "MoppLibConstants.h"

@interface MoppLibManager : NSObject

+ (MoppLibManager *)sharedInstance;

- (void)setupWithSuccess:(EmptySuccessBlock)success andFailure:(FailureBlock)failure;
- (MoppLibContainer *)getContainerWithPath:(NSString *)containerPath;
- (MoppLibContainer *)createContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath;
- (MoppLibContainer *)addDataFileToContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath;
- (MoppLibContainer *)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex;
- (NSArray *)getContainersIsSigned:(BOOL)isSigned;
- (void)addSignature:(MoppLibContainer *)moppContainer pin2:(NSString *)pin2 cert:(NSData *)cert success:(EmptySuccessBlock)success andFailure:(FailureBlock)failure;
- (NSString *)dataFileCalculateHashWithDigestMethod:(NSString *)method container:(MoppLibContainer *)moppContainer dataFileId:(NSString *)dataFileId;
- (NSString *)getMoppLibVersion;
@end

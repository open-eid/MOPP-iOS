//
//  MoppLibContainerActions.h
//  MoppLib
//
//  Created by Katrin Annuk on 03/02/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibContainer.h"
#import "MoppLibSignature.h"
#import "MoppLibConstants.h"

@interface MoppLibContainerActions : NSObject

+ (MoppLibContainerActions *)sharedInstance;

- (void)getContainerWithPath:(NSString *)containerPath success:(ContainerBlock)success failure:(FailureBlock)failure;
- (void)createContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath success:(ContainerBlock)success failure:(FailureBlock)failure;
- (void)addDataFileToContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath success:(ContainerBlock)success failure:(FailureBlock)failure;;
- (void)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex success:(ContainerBlock)success failure:(FailureBlock)failure;;

- (void)getContainersIsSigned:(BOOL)isSigned success:(void(^)(NSArray *containers))success failure:(FailureBlock)failure;

- (void)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath success:(ContainerBlock)success failure:(FailureBlock)failure;;
- (NSString *)getMoppLibVersion;
@end

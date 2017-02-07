//
//  MoppLibContainerActions.m
//  MoppLib
//
//  Created by Katrin Annuk on 03/02/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "MoppLibContainerActions.h"
#import "MoppLibDigidocManager.h"

@implementation MoppLibContainerActions

+ (MoppLibContainerActions *)sharedInstance {
  static dispatch_once_t pred;
  static MoppLibContainerActions *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void)getContainerWithPath:(NSString *)containerPath success:(ContainerBlock)success failure:(FailureBlock)failure {
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] getContainerWithPath:containerPath];
    dispatch_async(dispatch_get_main_queue(), ^{
      success(container);
    });
  });
}

- (void)createContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath success:(ContainerBlock)success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] createContainerWithPath:containerPath withDataFilePath:dataFilePath];
    dispatch_async(dispatch_get_main_queue(), ^{
      success(container);
    });
  });
  
}

- (void)addDataFileToContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath success:(ContainerBlock)success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] addDataFileToContainerWithPath:containerPath withDataFilePath:dataFilePath];
    dispatch_async(dispatch_get_main_queue(), ^{
      success(container);
    });
  });
  
}

- (void)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex success:(ContainerBlock)success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] removeDataFileFromContainerWithPath:containerPath atIndex:dataFileIndex];
    dispatch_async(dispatch_get_main_queue(), ^{
      success(container);
    });
  });
  
}

- (void)getContainersIsSigned:(BOOL)isSigned success:(void(^)(NSArray *containers))success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSArray *containers = [[MoppLibDigidocManager sharedInstance] getContainersIsSigned:isSigned];
    dispatch_async(dispatch_get_main_queue(), ^{
      success(containers);
    });
  });
}

- (void)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath success:(ContainerBlock)success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] removeSignature:moppSignature fromContainerWithPath:containerPath];
    dispatch_async(dispatch_get_main_queue(), ^{
      success(container);
    });
  });
}

- (NSString *)getMoppLibVersion {
  return [[MoppLibDigidocManager sharedInstance] getMoppLibVersion];
}

@end

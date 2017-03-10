//
//  MoppLibContainerActions.m
//  MoppLib
//
//  Created by Katrin Annuk on 03/02/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "MoppLibContainerActions.h"
#import "MoppLibDigidocManager.h"
#import "CardActionsManager.h"
#import "Reachability.h"
#import "MoppLibError.h"

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
    NSError *error;
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] getContainerWithPath:containerPath error:&error];
    dispatch_async(dispatch_get_main_queue(), ^{
      if (error) {
        failure(error);
      } else {
        success(container);
      }
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

- (void)container:(NSString *)containerPath saveDataFile:(NSString *)fileName to:(NSString *)path success:(void(^)(void))success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [[MoppLibDigidocManager sharedInstance] container:containerPath saveDataFile:fileName to:path];
    dispatch_async(dispatch_get_main_queue(), ^{
      success();
    });
  });
}

- (void)addSignature:(MoppLibContainer *)moppContainer controller:(UIViewController *)controller success:(void(^)(MoppLibContainer *container, BOOL signatureWasAdded))success failure:(FailureBlock)failure {
  
  Reachability *reachability = [Reachability reachabilityForInternetConnection];
  NetworkStatus networkStatus = [reachability currentReachabilityStatus];
  if (networkStatus == NotReachable) {
    failure([MoppLibError noInternetConnectionError]);
    return;
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    [[CardActionsManager sharedInstance] addSignature:moppContainer controller:controller success:^(MoppLibContainer *container, BOOL signatureWasAdded) {
      dispatch_async(dispatch_get_main_queue(), ^{
        success(container, signatureWasAdded);
      });
    } failure:^(NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        failure(error);
      });
    }];
  });
}

@end

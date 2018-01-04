//
//  MoppLibContainerActions.m
//  MoppLib
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

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
        error == nil ? success(container) : failure(error);
    });
  });
}

- (void)createContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths success:(ContainerBlock)success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSError *error;
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] createContainerWithPath:containerPath withDataFilePaths:dataFilePaths error:&error];
    dispatch_async(dispatch_get_main_queue(), ^{
      error == nil ? success(container) : failure(error);
    });
  });
  
}

- (void)addDataFilesToContainerWithPath:(NSString *)containerPath withDataFilePaths:(NSArray *)dataFilePaths success:(ContainerBlock)success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSError *error;
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] addDataFilesToContainerWithPath:containerPath withDataFilePaths:dataFilePaths error:&error];
    dispatch_async(dispatch_get_main_queue(), ^{
      error == nil ? success(container) : failure(error);
    });
  });
  
}

- (void)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex success:(ContainerBlock)success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSError *error;
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] removeDataFileFromContainerWithPath:containerPath atIndex:dataFileIndex error:&error];
    dispatch_async(dispatch_get_main_queue(), ^{
        error == nil ? success(container) : failure(error);
    });
  });
  
}

- (void)getContainersWithSuccess:(void(^)(NSArray *containers))success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSArray *containers = [[MoppLibDigidocManager sharedInstance] getContainers];
    dispatch_async(dispatch_get_main_queue(), ^{
      success(containers);
    });
  });
}

- (void)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath success:(ContainerBlock)success failure:(FailureBlock)failure {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSError *error;
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] removeSignature:moppSignature fromContainerWithPath:containerPath error:&error];
    dispatch_async(dispatch_get_main_queue(), ^{
      error == nil ? success(container) : failure(error);
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

- (void)addSignature:(NSString *)containerPath controller:(UIViewController *)controller success:(void(^)(MoppLibContainer *container, BOOL signatureWasAdded))success failure:(FailureBlock)failure {
  
  Reachability *reachability = [Reachability reachabilityForInternetConnection];
  NetworkStatus networkStatus = [reachability currentReachabilityStatus];
  if (networkStatus == NotReachable) {
    failure([MoppLibError noInternetConnectionError]);
    return;
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    [[CardActionsManager sharedInstance] addSignature:containerPath controller:controller success:^(MoppLibContainer *container, BOOL signatureWasAdded) {
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

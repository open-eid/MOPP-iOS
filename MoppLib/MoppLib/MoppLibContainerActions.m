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
  
  //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    MoppLibContainer *container = [[MoppLibDigidocManager sharedInstance] getContainerWithPath:containerPath];
   // dispatch_async(dispatch_get_main_queue(), ^{
      success(container);
   // });
  //});
}

- (MoppLibContainer *)createContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath {
  return [[MoppLibDigidocManager sharedInstance] createContainerWithPath:containerPath withDataFilePath:dataFilePath];
}

- (MoppLibContainer *)addDataFileToContainerWithPath:(NSString *)containerPath withDataFilePath:(NSString *)dataFilePath {
  return [[MoppLibDigidocManager sharedInstance] addDataFileToContainerWithPath:containerPath withDataFilePath:dataFilePath];
}

- (MoppLibContainer *)removeDataFileFromContainerWithPath:(NSString *)containerPath atIndex:(NSUInteger)dataFileIndex {
  return [[MoppLibDigidocManager sharedInstance] removeDataFileFromContainerWithPath:containerPath atIndex:dataFileIndex];
}

- (void)getContainersIsSigned:(BOOL)isSigned success:(void(^)(NSArray *containers))success failure:(FailureBlock)failure {
 // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSArray *containers = [[MoppLibDigidocManager sharedInstance] getContainersIsSigned:isSigned];
   // dispatch_async(dispatch_get_main_queue(), ^{
      success(containers);

   // });
 // });
}

- (MoppLibContainer *)removeSignature:(MoppLibSignature *)moppSignature fromContainerWithPath:(NSString *)containerPath {
  return [[MoppLibDigidocManager sharedInstance] removeSignature:moppSignature fromContainerWithPath:containerPath];
}

- (NSString *)getMoppLibVersion {
  return [[MoppLibDigidocManager sharedInstance] getMoppLibVersion];
}

@end

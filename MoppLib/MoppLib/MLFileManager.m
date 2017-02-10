//
//  MLFileManager.m
//  MoppLib
//
//  Created by Ants Käär on 17.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "MLFileManager.h"

@interface MLFileManager ()

@property (strong, nonatomic) NSFileManager *fileManager;

@end

@implementation MLFileManager

+ (MLFileManager *)sharedInstance {
  static dispatch_once_t pred;
  static MLFileManager *sharedInstance = nil;
  dispatch_once(&pred, ^{
    sharedInstance = [[self alloc] init];
    [sharedInstance setup];
  });
  return sharedInstance;
}

- (void)setup {
  self.fileManager = [NSFileManager defaultManager];
}

- (NSString *)documentsDirectoryPath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  return documentsDirectory;
}

- (NSString *)tslCachePath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
  NSString *libraryDirectory = [paths objectAtIndex:0];
  return libraryDirectory;
}

- (NSString *)filePathWithFileName:(NSString *)fileName {
  NSString *filePath = [[self documentsDirectoryPath] stringByAppendingPathComponent:fileName];
  return filePath;
}

#warning - support .ddoc in the future
- (NSArray *)getContainers {
  NSArray *supportedExtensions = @[@"bdoc",
                                   @"asice"];
  NSArray *allFiles = [self.fileManager contentsOfDirectoryAtPath:[self documentsDirectoryPath] error:nil];
  NSArray *containers = [allFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%@ CONTAINS SELF.pathExtension.lowercaseString", supportedExtensions]];
  
  NSArray *sortedContainers = [containers sortedArrayUsingComparator:^NSComparisonResult(id firstFile, id secondFile) {
    NSDate *firstDate = [[self fileAttributes:firstFile] fileModificationDate];
    NSDate *secondDate = [[self fileAttributes:secondFile] fileModificationDate];
    return [secondDate compare:firstDate];
  }];
  
  NSMutableArray *containerPaths = [NSMutableArray array];
  for (NSString *containerName in sortedContainers) {
    [containerPaths addObject:[self filePathWithFileName:containerName]];
  }
  return containerPaths;
}

- (NSDictionary *)fileAttributes:(NSString *)filePath {
  NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:filePath error:nil];
  if (fileAttributes) {
    return fileAttributes;
  }
  return nil;
}

- (void)copyFileWithPath:(NSString *)sourcePath toPath:(NSString *)destinationPath {
  NSError *error;
  [self.fileManager copyItemAtPath:sourcePath toPath:destinationPath error:&error];
  if (error) {
    MLLog(@"copyFileWithPath error: %@", error);
  }
}

- (BOOL)fileExistsAtPath:(NSString *)filePath {
  BOOL exists = [self.fileManager fileExistsAtPath:filePath];
  return exists;
}

@end

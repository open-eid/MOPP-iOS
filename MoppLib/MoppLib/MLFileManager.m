//
//  MLFileManager.m
//  MoppLib
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
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

- (NSString *)cacheDirectoryPath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *cacheDirectory = [paths objectAtIndex:0];
  return cacheDirectory;
}

- (NSString *)logsDirectoryPath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *cacheDirectory = [paths objectAtIndex:0];
  NSString *logsDirectory = [cacheDirectory stringByAppendingPathComponent:@"logs"];
  return logsDirectory;
}

- (NSString *)tslCachePath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
  NSString *libraryDirectory = [paths objectAtIndex:0];
  return libraryDirectory;
}

- (NSString *)filePathWithFileName:(NSString *)fileName {
  NSString *filePath = [[self cacheDirectoryPath] stringByAppendingPathComponent:fileName];
  return filePath;
}

- (NSArray<NSString *> *)getContainers {
  NSArray *supportedExtensions = @[@"bdoc",
                                   @"asice"];
  NSArray *allFiles = [self.fileManager contentsOfDirectoryAtPath:[self cacheDirectoryPath] error:nil];
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

- (NSDictionary<NSFileAttributeKey, id> *)fileAttributes:(NSString *)filePath {
  NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:filePath error:nil];
  return fileAttributes;
}

- (BOOL)fileExistsAtPath:(NSString *)filePath {
  BOOL exists = [self.fileManager fileExistsAtPath:filePath];
  return exists;
}

- (BOOL)createFolder:(NSString *)folderName {
    NSError* error;
    NSURL* cacheDirectory = [[NSURL alloc] initFileURLWithPath:[self cacheDirectoryPath]];
    
    NSURL* newFolder = [cacheDirectory URLByAppendingPathComponent:folderName];
    BOOL isFolderCreated = [[NSFileManager defaultManager] createDirectoryAtURL:newFolder withIntermediateDirectories:YES attributes:nil error:&error];
    if (!isFolderCreated) {
        MLLog(@"createFolder error: %@", error);
    }
    
    return isFolderCreated;
}

- (BOOL)folderExists:(NSString *)folderPath {
    BOOL isDirectory = NO;
    return [[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDirectory];
}

@end

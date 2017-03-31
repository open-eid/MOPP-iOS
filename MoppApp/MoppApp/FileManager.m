//
//  FileManager.m
//  MoppApp
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

#import "FileManager.h"
#import "DateFormatter.h"
#import "DefaultsHelper.h"
#import "Constants.h"
#import <MoppLib/MoppLib.h>

@interface FileManager ()

@property (strong, nonatomic) NSFileManager *fileManager;

@end

@implementation FileManager

+ (FileManager *)sharedInstance {
  static dispatch_once_t pred;
  static FileManager *sharedInstance = nil;
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

- (NSString *)tempDocumentsDirectoryPath {
  NSString *path = [[self documentsDirectoryPath] stringByAppendingString:@"/temp"];
  BOOL isDir;
  if(![self.fileManager fileExistsAtPath:path isDirectory:&isDir]) {
    NSError *error;
    [self.fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
  }
  return path;
}

- (NSString *)tempFilePathWithFileName:(NSString *)fileName {
  NSString *filePath = [[self tempDocumentsDirectoryPath] stringByAppendingPathComponent:fileName];
  return filePath;
}

- (NSString *)filePathWithFileName:(NSString *)fileName {
  NSString *filePath = [[self documentsDirectoryPath] stringByAppendingPathComponent:fileName];
  return filePath;
}

- (NSString *)uniqueFilePathWithFileName:(NSString *)fileName {
  return [self filePathWithFileName:fileName index:0];
}

- (NSString *)filePathWithFileName:(NSString *)fileName index:(int)index {
  NSString *filePath = [[self documentsDirectoryPath] stringByAppendingPathComponent:fileName];
  if (index > 0) {
    NSString *ext = [filePath pathExtension];
    NSString *withoutExt = [filePath substringToIndex:filePath.length - ext.length - 1];
    filePath = [NSString stringWithFormat:@"%@(%i).%@", withoutExt, index, ext];
  }
  
  if ([self.fileManager fileExistsAtPath:filePath isDirectory:NO]) {
    return [self filePathWithFileName:fileName index:index + 1];
  }
  return filePath;
}
  
- (NSString *)sharedDocumentsPath {
  NSURL *groupFolderUrl = [self.fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.ee.ria.digidoc.ios"];
  return [groupFolderUrl URLByAppendingPathComponent:@"Temp"].path;
}

- (NSArray *)sharedDocumentPaths {
  NSString *cachePath = [self sharedDocumentsPath];

  NSArray *files = [self.fileManager contentsOfDirectoryAtPath:[self sharedDocumentsPath] error:nil];
  NSMutableArray *array = [NSMutableArray new];
  for (NSString *file in files) {
    [array addObject:[NSString stringWithFormat:@"%@/%@", cachePath, file]];
  }
  return array;
}

- (void)removeFilesAtPaths:(NSArray *)paths {
  for (NSString *file in paths) {
    [self removeFileWithPath:file];
  }
}
- (void)clearSharedCache {
  NSArray *cachedDocs = [self sharedDocumentPaths];
  for (NSString *file in cachedDocs) {
    [self removeFileWithPath:file];
  }
}

- (NSString *)createTestContainer {
  NSString *fileName = [NSString stringWithFormat:@"%@.%@", [[DateFormatter sharedInstance] HHmmssddMMYYYYToString:[NSDate date]], [DefaultsHelper getNewContainerFormat]];
  
  NSString *bdocPath = [[NSBundle mainBundle] pathForResource:@"test1" ofType:@"bdoc"];
  NSData *bdocData = [NSData dataWithContentsOfFile:bdocPath];
  
  [self createFileAtPath:[self filePathWithFileName:fileName] contents:bdocData];
  
  return fileName;
}

- (void)createFileAtPath:(NSString *)filePath contents:(NSData *)fileContents {
  [self.fileManager createFileAtPath:filePath contents:fileContents attributes:nil];
  [[MoppLibContainerActions sharedInstance] getContainerWithPath:filePath success:^(MoppLibContainer *container) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationContainerChanged object:nil userInfo:@{kKeyContainerNew:container}];
    
  } failure:^(NSError *error) {
      
  }];
}

- (void)removeFileWithName:(NSString *)fileName {
  NSError *error;
  [self.fileManager removeItemAtPath:[self filePathWithFileName:fileName] error:&error];
  if (error) {
    MSLog(@"removeFileWithName error: %@", error);
  }
}

- (void)removeFileWithPath:(NSString *)filePath {
  NSError *error;
  [self.fileManager removeItemAtPath:filePath error:&error];
  if (error) {
    MSLog(@"removeFileWithPath error: %@", error);
  }
}

- (BOOL)fileExists:(NSString *)sourcePath {
  return [self.fileManager fileExistsAtPath:sourcePath];
}

- (void)moveFileWithPath:(NSString *)sourcePath toPath:(NSString *)destinationPath overwrite:(BOOL)overwrite error:(NSError **)error {
  
  if (overwrite && [self fileExists:destinationPath]) {
    [self removeFileWithPath:destinationPath];
  }
  
  NSError *err;
  [self.fileManager moveItemAtPath:sourcePath toPath:destinationPath error:&err];
  if (error) {
    MSLog(@"moveFileWithPath error: %@", err);
    *error = err;
  }
}

- (NSString *)copyFileWithPath:(NSString *)sourcePath toPath:(NSString *)destinationPath {
  return [self copyFileWithPath:sourcePath toPath:destinationPath duplicteCount:0];
}

- (NSString *)copyFileWithPath:(NSString *)sourcePath toPath:(NSString *)destinationPath duplicteCount:(int)count {
  NSString *finalName = destinationPath;
  
  if (count > 0) {
    NSString *ext = [destinationPath pathExtension];
    finalName = [finalName substringToIndex:finalName.length - ext.length - 1];
    finalName = [finalName stringByAppendingString:[NSString stringWithFormat:@"(%i).%@", count, ext]];
  }
  
  if ([self fileExists:finalName]) {
    return [self copyFileWithPath:sourcePath toPath:destinationPath duplicteCount:count+1];
  }
  
  NSError *error;
  [self.fileManager copyItemAtPath:sourcePath toPath:finalName error:&error];
  if (error) {
    MSLog(@"copyFileWithPath error: %@", error);
  }
  
  return finalName;
}

@end

//
//  FileManager.m
//  MoppApp
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

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

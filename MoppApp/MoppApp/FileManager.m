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

- (void)moveFileWithPath:(NSString *)sourcePath toPath:(NSString *)destinationPath {
  NSError *error;
  [self.fileManager moveItemAtPath:sourcePath toPath:destinationPath error:&error];
  if (error) {
    MSLog(@"moveFileWithPath error: %@", error);
  }
}

- (void)copyFileWithPath:(NSString *)sourcePath toPath:(NSString *)destinationPath {
  NSError *error;
  [self.fileManager copyItemAtPath:sourcePath toPath:destinationPath error:&error];
  if (error) {
    MSLog(@"copyFileWithPath error: %@", error);
  }
}

@end

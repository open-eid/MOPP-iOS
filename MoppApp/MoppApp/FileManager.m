//
//  FileManager.m
//  MoppApp
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "FileManager.h"
#import "DateFormatter.h"

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
  NSString *extension = @"bdoc";
  if (arc4random_uniform(2) == 0) {
    extension = @"asice";
  }
  NSString *fileName = [NSString stringWithFormat:@"%@.%@", [[DateFormatter sharedInstance] HHmmssddMMYYYYToString:[NSDate date]], extension];
  
  NSString *bdocPath = [[NSBundle mainBundle] pathForResource:@"test1" ofType:@"bdoc"];
  NSData *bdocData = [NSData dataWithContentsOfFile:bdocPath];
  
  [self createFileAtPath:[self filePathWithFileName:fileName] contents:bdocData];
  
  return fileName;
}

- (void)createFileAtPath:(NSString *)filePath contents:(NSData *)fileContents {
  [self.fileManager createFileAtPath:filePath contents:fileContents attributes:nil];
}

- (void)removeFileWithName:(NSString *)fileName {
  [self.fileManager removeItemAtPath:[self filePathWithFileName:fileName] error:nil];
}

- (void)removeFileWithPath:(NSString *)filePath {
  [self.fileManager removeItemAtPath:filePath error:nil];
}


@end

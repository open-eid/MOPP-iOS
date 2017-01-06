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

- (void)createTestBDoc {
  NSString *fileName = [NSString stringWithFormat:@"%@.bdoc", [[DateFormatter sharedInstance] HHmmssddMMYYYYToString:[NSDate date]]];
  
  NSString *bdocPath = [[NSBundle mainBundle] pathForResource:@"test1" ofType:@"bdoc"];
  NSData *bdocData = [NSData dataWithContentsOfFile:bdocPath];
  
  [self createFileAtPath:[self filePathWithFileName:fileName] contents:bdocData];
}

- (void)createFileAtPath:(NSString *)filePath contents:(NSData *)fileContents {
  [self.fileManager createFileAtPath:filePath contents:fileContents attributes:nil];
}

- (void)removeFileWithName:(NSString *)fileName {
  [self.fileManager removeItemAtPath:[self filePathWithFileName:fileName] error:nil];
}

- (NSArray *)getBDocFiles {
  return [self.fileManager contentsOfDirectoryAtPath:[self documentsDirectoryPath] error:nil];
}

- (NSDate *)fileCreationDate:(NSString *)fileName {
  NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:[self filePathWithFileName:fileName] error:nil];
  if (fileAttributes) {
    NSDate *date = (NSDate *)[fileAttributes objectForKey:NSFileCreationDate];
    return date;
  }
  return nil;
}

@end

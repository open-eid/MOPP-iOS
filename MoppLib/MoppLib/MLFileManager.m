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

- (NSString *)filePathWithFileName:(NSString *)fileName {
  NSString *filePath = [[self documentsDirectoryPath] stringByAppendingPathComponent:fileName];
  return filePath;
}

#warning - support .ddoc in the future
- (NSArray *)getContainers {
  NSArray *supportedExtensions = @[@"bdoc", @"asice"];
  NSArray *allFiles = [self.fileManager contentsOfDirectoryAtPath:[self documentsDirectoryPath] error:nil];
  NSArray *containers = [allFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension IN %@", supportedExtensions]];
  
  NSArray *sortedContainers = [containers sortedArrayUsingComparator:^NSComparisonResult(id firstFile, id secondFile) {
    NSDate *firstDate = [[self fileAttributes:firstFile] fileModificationDate];
    NSDate *secondDate = [[self fileAttributes:secondFile] fileModificationDate];
    return [secondDate compare:firstDate];
  }];
  
  return sortedContainers;
}

- (NSDictionary *)fileAttributes:(NSString *)fileName {
  NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:[self filePathWithFileName:fileName] error:nil];
  if (fileAttributes) {
    return fileAttributes;
  }
  return nil;
}

@end

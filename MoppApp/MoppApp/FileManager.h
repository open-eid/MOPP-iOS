//
//  FileManager.h
//  MoppApp
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileManager : NSObject

+ (FileManager *)sharedInstance;

- (NSString *)filePathWithFileName:(NSString *)fileName;
- (NSString *)tempFilePathWithFileName:(NSString *)fileName;
- (NSString *)createTestContainer;
- (void)removeFileWithName:(NSString *)fileName;
- (void)removeFileWithPath:(NSString *)filePath;
- (void)moveFileWithPath:(NSString *)sourcePath toPath:(NSString *)destinationPath overwrite:(BOOL)overwrite error:(NSError **)error;
- (NSString *)copyFileWithPath:(NSString *)sourcePath toPath:(NSString *)destinationPath;
- (BOOL)fileExists:(NSString *)sourcePath;
@end

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
- (void)createTestBDoc;
- (void)removeFileWithName:(NSString *)fileName;
- (NSArray *)getBDocFiles;
- (NSDate *)fileCreationDate:(NSString *)fileName;

@end

//
//  FileManager.h
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

#import <Foundation/Foundation.h>

@interface FileManager : NSObject

+ (FileManager *)sharedInstance;

- (NSString *)filePathWithFileName:(NSString *)fileName;
- (NSString *)uniqueFilePathWithFileName:(NSString *)fileName;

- (NSString *)tempFilePathWithFileName:(NSString *)fileName;
- (NSString *)createTestContainer;

- (void)removeFileWithName:(NSString *)fileName;
- (void)removeFileWithPath:(NSString *)filePath;
- (void)removeFilesAtPaths:(NSArray *)paths;

- (void)moveFileWithPath:(NSString *)sourcePath toPath:(NSString *)destinationPath overwrite:(BOOL)overwrite error:(NSError **)error;
- (NSString *)copyFileWithPath:(NSString *)sourcePath toPath:(NSString *)destinationPath;
- (BOOL)fileExists:(NSString *)sourcePath;
- (NSArray *)sharedDocumentPaths;
- (void)clearSharedCache;
@end

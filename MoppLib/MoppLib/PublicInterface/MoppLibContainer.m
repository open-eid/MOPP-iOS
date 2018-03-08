//
//  MoppLibContainer.m
//  MoppLib
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

#import "MoppLibContainer.h"
#import "MoppLibDataFile.h"

@implementation MoppLibContainer

- (BOOL)isSigned {
  return self.signatures.count != 0;
}

- (BOOL)isEmpty {
  return self.dataFiles.count != 0;
}

- (BOOL)isDDocType {
  return [self.fileName hasSuffix:@".ddoc"];
}
- (BOOL)isAsiceType {
  return [self.fileName hasSuffix:@".asice"] || [self.fileName hasSuffix:@".sce"];
}

- (BOOL)isLegacyType {
    NSString *fileNameLowercase = [self.fileName lowercaseString];
    return
        [fileNameLowercase hasSuffix:@".adoc"]    ||
        [fileNameLowercase hasSuffix:@".edoc"]    ||
        [fileNameLowercase hasSuffix:@".ddoc"]    ||
        [fileNameLowercase hasSuffix:@".asics"]   ||
        [fileNameLowercase hasSuffix:@".scs"]     ||
        [fileNameLowercase hasSuffix:@".pdf"];
}

- (NSString *)getNextSignatureId {
  NSMutableArray *exitingIds = [[NSMutableArray alloc] init];
  for (MoppLibDataFile *dataFile in self.dataFiles) {
    [exitingIds addObject:dataFile.fileId];
  }
  int nextId = 0;
  while ([exitingIds containsObject:[NSString stringWithFormat:@"S%d", nextId]]) {
    ++nextId;
  }
  return [NSString stringWithFormat:@"S%d", nextId];
}

- (NSString *)fileNameWithoutExtension {
  return [self.fileName stringByDeletingPathExtension];
}

@end

//
//  MoppLibContainer.m
//  MoppLib
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

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
  return [self.fileName hasSuffix:@".asice"];
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
@end

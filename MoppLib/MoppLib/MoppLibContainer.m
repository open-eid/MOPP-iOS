//
//  MoppLibContainer.m
//  MoppLib
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import "MoppLibContainer.h"

@implementation MoppLibContainer

- (BOOL)isSigned {
  return self.signatures.count != 0;
}

- (BOOL)isEmpty {
  return self.dataFiles.count != 0;
}

@end

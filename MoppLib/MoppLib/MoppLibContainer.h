//
//  MoppLibContainer.h
//  MoppLib
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MoppLibContainer : NSObject

@property (strong, nonatomic) NSString *fileName;
@property (strong, nonatomic) NSString *filePath;
@property (strong, nonatomic) NSDictionary *fileAttributes;
@property (strong, nonatomic) NSArray *dataFiles;
@property (strong, nonatomic) NSArray *signatures;

@end

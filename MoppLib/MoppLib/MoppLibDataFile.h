//
//  MoppLibDataFile.h
//  MoppLib
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MoppLibDataFile : NSObject

@property (strong, nonatomic) NSString *mediaType;
@property (strong, nonatomic) NSString *fileId;
@property (strong, nonatomic) NSString *fileName;
@property (assign, nonatomic) long fileSize;

@end

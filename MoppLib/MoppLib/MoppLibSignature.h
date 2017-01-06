//
//  MoppLibSignature.h
//  MoppLib
//
//  Created by Ants Käär on 06.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MoppLibSignature : NSObject

@property (strong, nonatomic) NSString *subjectName;
@property (strong, nonatomic) NSString *timestamp;
@property (assign, nonatomic) BOOL isValid;

@end

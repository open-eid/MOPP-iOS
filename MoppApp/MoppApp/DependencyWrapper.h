//
//  DepencenyWrapper.h
//  MoppApp
//
//  Created by Olev Abel on 1/26/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DependencyWrapper : NSObject

@property (nonatomic, strong) NSString *dependencyName;
@property (nonatomic, strong) NSString *licenseName;
@property (nonatomic, strong) NSString *licenseLink;

-(id)initWithDependencyName:(NSString *)dependencyName licenseName:(NSString *)licenseName licenseLink:(NSString *)licenseLink;

@end

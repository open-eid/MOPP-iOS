//
//  Session.h
//  MoppApp
//
//  Created by Ants Käär on 19.01.17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Session : NSObject

+ (Session *)sharedInstance;

- (void)setup;

@end

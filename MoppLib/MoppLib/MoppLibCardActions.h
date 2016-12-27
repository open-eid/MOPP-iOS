//
//  MoppLibCardActions.h
//  MoppLib
//
//  Created by Katrin Annuk on 27/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface MoppLibCardActions : NSObject
+ (void)setupWithPeripheral:(CBPeripheral *)peripheral success:(void(^)(NSData *))success failure:(void(^)(NSError *))failure;

@end

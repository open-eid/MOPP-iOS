//
//  CardActionsManager.h
//  MoppLib
//
//  Created by Katrin Annuk on 23/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CardCommands.h"
//#import "MoppLibPersonalData.h"

@interface CardActionsManager : NSObject
+ (CardActionsManager *)sharedInstance;

- (void)setupWithPeripheral:(CBPeripheral *)peripheral success:(void(^)(NSData *))success failure:(void(^)(NSError *))failure;

- (void)cardPersonalDataWithViewController:(UIViewController *)controller success:(void(^)(MoppLibPersonalData *))success failure:(void(^)(NSError *))failure;
@end

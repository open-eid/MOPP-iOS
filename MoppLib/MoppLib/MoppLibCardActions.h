//
//  MoppLibCardActions.h
//  MoppLib
//
//  Created by Katrin Annuk on 27/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#import "MoppLibPersonalData.h"

@protocol MoppLibCardActionsDelegate;

@interface MoppLibCardActions : NSObject

/**
 * Reads personal data file from card
 *
 */
+ (void)cardPersonalDataWithViewController:(UIViewController *)controller success:(void(^)(MoppLibPersonalData *))success failure:(void(^)(NSError *))failure;

@end

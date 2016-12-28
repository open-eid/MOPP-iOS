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

@interface MoppLibCardActions : NSObject

/**
 * Reads personal data file from card
 *
 */
+ (void)cardPersonalDataWithViewController:(UIViewController *)controller success:(void(^)(NSData *))success failure:(void(^)(NSError *))failure;
@end

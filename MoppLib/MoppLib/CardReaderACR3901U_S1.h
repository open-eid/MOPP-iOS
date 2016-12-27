//
//  CardReaderACR3901U_S1.h
//  MoppLib
//
//  Created by Katrin Annuk on 22/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CardReaderWrapper.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "MoppLibConstants.h"

@interface CardReaderACR3901U_S1 : NSObject <CardReaderWrapper>

/**
 * Performs peripheral detection, attaching and authenticating reader.
 *
 * @param success   block to be caller on successful execution.
 * @param failure   block to be called on failed execution of request. 
 */
- (void)setupWithPeripheral:(CBPeripheral *)peripheral success:(DataSuccessBlock)success failure:(FailureBlock)failure;
@end

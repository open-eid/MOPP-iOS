//
//  CardReaderACR3901U_S1.h
//  MoppLib
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#import <Foundation/Foundation.h>
#import "CardReaderWrapper.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "MoppLibConstants.h"
#import "MoppLibCardReaderManager.h"

@protocol CardReaderACR3901U_S1Delegate <NSObject>
- (void)cardReaderACR3901U_S1StatusDidChange:(MoppLibCardReaderStatus)status;
@end

@interface CardReaderACR3901U_S1 : NSObject <CardReaderWrapper>

@property (nonatomic, strong) id<CardReaderWrapperDelegate> delegate;
@property (nonatomic, strong) id<CardReaderACR3901U_S1Delegate> cr3901U_S1Delegate;
/**
 * Performs peripheral detection, attaching and authenticating reader.
 *
 * @param success   block to be caller on successful execution.
 * @param failure   block to be called on failed execution of request. 
 */
- (void)setupWithPeripheral:(CBPeripheral *)peripheral success:(DataSuccessBlock)success failure:(FailureBlock)failure;
@end

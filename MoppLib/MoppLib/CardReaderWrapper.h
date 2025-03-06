//
//  CardReaderWrapper.h
//  MoppLib
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
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

#import "MoppLibConstants.h"

typedef void (^SCDataSuccessBlock)(NSData *responseData, UInt16 sw);
@protocol CardReaderWrapper <NSObject>

/**
 * Transmits command and gets response from card
 *
 * @param commandHex    command in hex
 * @param success   block to be called when card action is completed successfully
 * @param failure   block to be called when executing card action fails
 */
- (void)transmitCommand:(const NSString *)commandHex success:(SCDataSuccessBlock)success failure:(FailureBlock)failure;

/**
 * Transmits command and gets response from card, additionally checks if result is 9000
 *
 * @param commandHex    command in hex
 * @param success   block to be called when card action is completed successfully
 * @param failure   block to be called when executing card action fails
 */
- (void)transmitCommandChecked:(const NSString *)commandHex success:(DataSuccessBlock)success failure:(FailureBlock)failure;

/**
 * Powers on card
 *
 * @param success   block to be called when card action is completed successfully
 * @param failure   block to be called when executing card action fails
 */
- (void)powerOnCard:(DataSuccessBlock)success failure:(FailureBlock)failure;

/**
 * Checks if card is inserted in reader
 *
 * @return Returns boolean attribute to indicate whether card is inserted or not
 */
- (BOOL)isCardInserted;

/**
 * Checks if card reader is connected
 *
 * @return YES if card reader is connected, NO otherwise
 */
- (BOOL)isConnected;

/**
 * Checks if card is powered on
 *
 * @return Returns boolean attribute to indicate whether card is powered on or not
 */
- (BOOL)isCardPoweredOn;

@end

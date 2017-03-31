//
//  MoppLibCardActions.h
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
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#import "MoppLibConstants.h"

@protocol MoppLibCardActionsDelegate;

@interface MoppLibCardActions : NSObject

/** Gets minimal public personal data from ID card. This includes name, id code, birth date, nationality, document number and document expiry date.
 *
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action. Includes card owner public personal data as MoppLibPersonalData. Some of the parameters in MoppLibPersonalData may not be filled. To get all available data use cardPersonalDataWithViewController:success:failure:
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)minimalCardPersonalDataWithViewController:(UIViewController *)controller success:(PersonalDataBlock)success failure:(FailureBlock)failure;

/** Gets public personal data from ID card.
*
* @param controller    ViewController to be used for card reader selection if needed.
* @param success       Block to be called on successful completion of action. Includes card owner public personal data as MoppLibPersonalData.
* @param failure       Block to be called when action fails. Includes error.
*/
+ (void)cardPersonalDataWithViewController:(UIViewController *)controller success:(PersonalDataBlock)success failure:(FailureBlock)failure;

/**
 * Checks if reader is connected to device.
 *
 * @return YES if reader is connected, NO otherwise
 */
+ (BOOL)isReaderConnected;

/**
 * Checks if card is inserted to card reader.
 *
 * @param completion    Block to be called when action is complete. Includes BOOL to represent card status - YES if card is detected in reader, NO if card is not found.
 */
+ (void)isCardInserted:(void(^)(BOOL)) completion;

/**
 * Gets signing certificate data.
 *
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action. Includes signing certificate data as MoppLibCertData
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)signingCertWithViewController:(UIViewController *)controller success:(CertDataBlock)success failure:(FailureBlock)failure;

/**
 * Gets authentication certificate data.
 *
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action. Includes authentication certificate data as MoppLibCertData
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)authenticationCertWithViewController:(UIViewController *)controller success:(CertDataBlock)success failure:(FailureBlock)failure;

/**
 * Gets PIN1 retry counter value.
 *
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action. Includes retry counter value as NSNumber
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)pin1RetryCountWithViewController:(UIViewController *)controller success:(void (^)(NSNumber *))success failure:(FailureBlock)failure;

/**
 * Gets PIN2 retry counter value.
 *
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action. Includes retry counter value as NSNumber
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)pin2RetryCountWithViewController:(UIViewController *)controller success:(void (^)(NSNumber *))success failure:(FailureBlock)failure;

/**
 * Gets PUK retry counter value.
 *
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action. Includes retry counter value as NSNumber
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)pukRetryCountWithViewController:(UIViewController *)controller success:(void (^)(NSNumber *))success failure:(FailureBlock)failure;

@end

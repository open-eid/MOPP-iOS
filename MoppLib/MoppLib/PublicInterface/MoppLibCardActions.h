//
//  MoppLibCardActions.h
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

@interface MoppLibCardActions : NSObject

/** Gets public personal data from ID card.
*
* @param success       Block to be called on successful completion of action. Includes card owner public personal data as MoppLibPersonalData.
* @param failure       Block to be called when action fails. Includes error.
*/
+ (void)cardPersonalDataWithSuccess:(PersonalDataBlock)success failure:(FailureBlock)failure;

/**
 * Gets signing certificate data.
 *
 * @param success       Block to be called on successful completion of action. Includes signing certificate data as MoppLibCertData
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)signingCertificateWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure;

/**
 * Gets authentication certificate data.
 *
 * @param success       Block to be called on successful completion of action. Includes authentication certificate data as MoppLibCertData
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)authenticationCertificateWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure;

/**
 * Gets PIN1 retry counter value.
 *
 * @param success       Block to be called on successful completion of action. Includes retry counter value as NSNumber
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)pin1RetryCountWithSuccess:(NumberBlock)success failure:(FailureBlock)failure;

/**
 * Gets PIN2 retry counter value.
 *
 * @param success       Block to be called on successful completion of action. Includes retry counter value as NSNumber
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)pin2RetryCountWithSuccess:(NumberBlock)success failure:(FailureBlock)failure;

/**
 * Gets PUK retry counter value.
 *
 * @param success       Block to be called on successful completion of action. Includes retry counter value as NSNumber
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)pukRetryCountWithSuccess:(NumberBlock)success failure:(FailureBlock)failure;

@end

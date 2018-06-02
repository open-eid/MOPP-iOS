//
//  MoppLibPinActions.h
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
#import <UIKit/UIKit.h>
#import "MoppLibConstants.h"

@interface MoppLibPinActions : NSObject

/**
 * Changes current PUK to new one by using current PUK for verification.
 *
 * @param newPuk       New PUK that will replace current PUK
 * @param oldPuk       Current PUK to be used for verification
 * @param success       Block to be called on successful completion of action
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)changePukTo:(NSString *)newPuk withOldPuk:(NSString *)oldPuk success:(VoidBlock)success failure:(FailureBlock)failure;

/**
 * Changes current PIN1 to new one by using current PIN1 for verification.
 *
 * @param newPin1       New PIN1 that will replace current PIN1
 * @param oldPin1       Current PIN1 to be used for verification
 * @param success       Block to be called on successful completion of action
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)changePin1To:(NSString *)newPin1 withOldPin1:(NSString *)oldPin1 success:(VoidBlock)success failure:(FailureBlock)failure;

/**
 * Changes current PIN1 to new one by using current PUK for verification.
 *
 * @param newPin1       New PIN1 that will replace current PIN1.
 * @param puk           Current PUK to be used for verification.
 * @param success       Block to be called on successful completion of action.
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)changePin1To:(NSString *)newPin1 withPuk:(NSString *)puk success:(VoidBlock)success failure:(FailureBlock)failure;

/**
 * Changes current PIN2 to new one by using current PIN2 for verification.
 *
 * @param newPin2       New PI21 that will replace current PIN2.
 * @param oldPin2       Current PIN2 to be used for verification.
 * @param success       Block to be called on successful completion of action.
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)changePin2To:(NSString *)newPin2 withOldPin2:(NSString *)oldPin2 success:(VoidBlock)success failure:(FailureBlock)failure;

/**
 * Changes current PIN2 to new one by using current PUK for verification.
 *
 * @param newPin2       New PIN2 that will replace current PIN2.
 * @param puk           Current PUK to be used for verification.
 * @param success       Block to be called on successful completion of action.
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)changePin2To:(NSString *)newPin2 withPuk:(NSString *)puk success:(VoidBlock)success failure:(FailureBlock)failure;

/**
 * Unblocks PIN1 by changing current PIN1.
 *
 * @param puk           Current PUK to be used for verification.
 * @param newPin1       New PIN1 that will replace current PIN1.
 * @param success       Block to be called on successful completion of action.
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)unblockPin1WithPuk:(NSString *)puk newPin1:(NSString *)newPin1 success:(VoidBlock)success failure:(FailureBlock)failure;

/**
 * Unblocks PIN2 by changing current PIN2.
 *
 * @param puk           Current PUK to be used for verification.
 * @param newPin2       New PIN2 that will replace current PIN2.
 * @param success       Block to be called on successful completion of action.
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)unblockPin2WithPuk:(NSString *)puk newPin2:(NSString *)newPin2 success:(VoidBlock)success failure:(FailureBlock)failure;


+ (NSArray *)forbiddenPin1s;
+ (NSArray *)forbiddenPin2s;
+ (NSArray *)forbiddenPuks;
+ (int)pin1MinLength;
+ (int)pin2MinLength;
+ (int)pin1MaxLength;
+ (int)pin2MaxLength;
+ (int)pukMinLength;
+ (int)pukMaxLength;
@end

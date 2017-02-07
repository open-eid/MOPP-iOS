//
//  MoppLibPinActions.h
//  MoppLib
//
//  Created by Katrin Annuk on 09/01/17.
//  Copyright © 2017 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MoppLibConstants.h"

@interface MoppLibPinActions : NSObject

/**
 * Changes current PIN1 to new one by using current PIN1 for verification.
 *
 * @param newPin1       New PIN1 that will replace current PIN1
 * @param oldPin1       Current PIN1 to be used for verification
 * @param controller    ViewController to be used for card reader selection if needed
 * @param success       Block to be called on successful completion of action
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)changePin1To:(NSString *)newPin1 withOldPin1:(NSString *)oldPin1 viewController:(UIViewController *)controller success:(VoidBlock)success failure:(FailureBlock)failure;

/**
 * Changes current PIN1 to new one by using current PUK for verification.
 *
 * @param newPin1       New PIN1 that will replace current PIN1.
 * @param puk           Current PUK to be used for verification.
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action.
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)changePin1To:(NSString *)newPin1 withPuk:(NSString *)puk viewController:(UIViewController *)controller success:(VoidBlock)success failure:(FailureBlock)failure;

/**
 * Changes current PIN2 to new one by using current PIN2 for verification.
 *
 * @param newPin2       New PI21 that will replace current PIN2.
 * @param oldPin2       Current PIN2 to be used for verification.
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action.
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)changePin2To:(NSString *)newPin2 withOldPin2:(NSString *)oldPin2 viewController:(UIViewController *)controller success:(VoidBlock)success failure:(FailureBlock)failure;

/**
 * Changes current PIN2 to new one by using current PUK for verification.
 *
 * @param newPin2       New PIN2 that will replace current PIN2.
 * @param puk           Current PUK to be used for verification.
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action.
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)changePin2To:(NSString *)newPin2 withPuk:(NSString *)puk viewController:(UIViewController *)controller success:(VoidBlock)success failure:(FailureBlock)failure;

/**
 * Unblocks PIN1 by changing current PIN1.
 *
 * @param puk           Current PUK to be used for verification.
 * @param newPin1       New PIN1 that will replace current PIN1.
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action.
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)unblockPin1WithPuk:(NSString *)puk newPin1:(NSString *)newPin1 viewController:(UIViewController *)controller success:(VoidBlock)success failure:(FailureBlock)failure;

/**
 * Unblocks PIN2 by changing current PIN2.
 *
 * @param puk           Current PUK to be used for verification.
 * @param newPin2       New PIN2 that will replace current PIN2.
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action.
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)unblockPin2WithPuk:(NSString *)puk newPin2:(NSString *)newPin2 viewController:(UIViewController *)controller success:(VoidBlock)success failure:(FailureBlock)failure;


+ (NSArray *)forbiddenPin1s;
+ (NSArray *)forbiddenPin2s;
+ (int)pin1MinLength;
+ (int)pin2MinLength;
+ (int)pin1MaxLength;
+ (int)pin2MaxLength;
@end

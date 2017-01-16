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
#import "MoppLibCertData.h"

@protocol MoppLibCardActionsDelegate;

@interface MoppLibCardActions : NSObject

/** Gets public personal data from ID card.
*
* @param controller    ViewController to be used for card reader selection if needed.
* @param success       Block to be called on successful completion of action. Includes card owner public personal data as MoppLibPersonalData.
* @param failure       Block to be called when action fails. Includes error.
*/
+ (void)cardPersonalDataWithViewController:(UIViewController *)controller success:(void(^)(MoppLibPersonalData *))success failure:(void(^)(NSError *))failure;

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
+ (void)signingCertWithViewController:(UIViewController *)controller success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure;

/**
 * Gets authentication certificate data.
 *
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action. Includes authentication certificate data as MoppLibCertData
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)authenticationCertWithViewController:(UIViewController *)controller success:(void (^)(MoppLibCertData *))success failure:(void (^)(NSError *))failure;

/**
 * Gets PIN1 retry counter value.
 *
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action. Includes retry counter value as NSNumber
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)pin1RetryCountWithViewController:(UIViewController *)controller success:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure;

/**
 * Gets PIN2 retry counter value.
 *
 * @param controller    ViewController to be used for card reader selection if needed.
 * @param success       Block to be called on successful completion of action. Includes retry counter value as NSNumber
 * @param failure       Block to be called when action fails. Includes error.
 */
+ (void)pin2RetryCountWithViewController:(UIViewController *)controller success:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure;
@end

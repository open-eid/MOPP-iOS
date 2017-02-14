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

+ (void)addSignature:(MoppLibContainer *)moppContainer pin2:(NSString *)pin2 controller:(UIViewController *)controller success:(ContainerBlock)success failure:(FailureBlock)failure;
@end

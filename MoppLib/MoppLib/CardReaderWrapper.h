//
//  CardReaderWrapper.h
//  MoppLib
//
//  Created by Katrin Annuk on 22/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoppLibConstants.h"

@protocol CardReaderWrapper <NSObject>

/**
 * Transmits command and gets response from card
 *
 * @param commandHex    command in hex
 * @param success   block to be called when card action is completed successfully
 * @param failure   block to be called when executing card action fails
 */
- (void)transmitCommand:(NSString *)commandHex success:(DataSuccessBlock)success failure:(FailureBlock)failure;

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
 * @param completion   block to be called when card action is completed. Block includes boolean attribute to indicate whether card is inserted or not
 */
- (void)isCardInserted:(void(^)(BOOL)) completion;

/**
 * Checks if card reader is connected
 *
 * @return YES if card reader is connected, NO otherwise
 */
- (BOOL)isConnected;

/**
 * Checks if card is powered on
 *
 * @param completion   block to be called when card action is completed. Block includes boolean attribute to indicate whether card is powered on or not
 */
- (void)isCardPoweredOn:(void(^)(BOOL)) completion;

- (void)resetReader;

- (void)updateCardStatusWithSuccess:(DataSuccessBlock)success failure:(FailureBlock)failure;

@end

typedef NS_ENUM(NSUInteger, CardStatus) {
  CardStatusPresent,
  CardStatusAbsent
};

@protocol CardReaderWrapperDelegate <NSObject>

- (void)cardStatusUpdated:(CardStatus)status;

@end


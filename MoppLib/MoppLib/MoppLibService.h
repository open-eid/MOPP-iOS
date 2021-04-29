//
//  MoppLibService.h
//  MoppLib
//
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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
#import "MoppLibContainer.h"
#import "MoppLibConstants.h"

@interface MoppLibService : NSObject

@property (nonatomic) BOOL willPollForSignatureResponse;



+ (MoppLibService *)sharedInstance;

/**
 * Method to start mobile ID signing process. This method will invoke SIM toolkit.
 *
 * @param containerPath Path to container.
 * @param idCode       Personal identification code.
 * @param language     Language code for SIM tool kit. Possible values: ENG, EST, RUS, LIT.
 * @param phoneNumber  Mobile phone number. Must use country code!.
 * @param completion   Block to be called on successful completion of request. Will return MoppLibMobileCreateSignatureResponse, that contains challengeId, which must be displayed in UI.
 * @param signatureStatus Block returning three objects: MoppLibContainer, NSError, NSString for request status. The possible three scenarios are: 
                                                                                                                    1) request failed - NSError object is populated, other two are nil.
                                                                                                                    2) polling start  - NSString object is populated, other two are nil.
                                                                                                                    3) signature obtained - MoppLibContainer object is populated, other two are nil.
 */
- (void)mobileCreateSignatureWithContainer:(NSString *)containerPath
                                    idCode:(NSString *)idCode
                                  language:(NSString *)language
                               phoneNumber:(NSString *)phoneNumber
                            withCompletion:(MobileCreateSignatureResponseBlock)completion
                                 andStatus:(SignatureStatusBlock)signatureStatus;

/**
 * Stops polling for signature status.
 */
- (void)cancelMobileSignatureStatusPolling;
@end

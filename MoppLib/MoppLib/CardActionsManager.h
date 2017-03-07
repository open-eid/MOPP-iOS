//
//  CardActionsManager.h
//  MoppLib
//
//  Created by Katrin Annuk on 23/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CardCommands.h"

@interface CardActionsManager : NSObject
+ (CardActionsManager *)sharedInstance;

- (void)minimalCardPersonalDataWithViewController:(UIViewController *)controller success:(PersonalDataBlock)success failure:(FailureBlock)failure;

- (void)cardPersonalDataWithViewController:(UIViewController *)controller success:(PersonalDataBlock)success failure:(FailureBlock)failure;

- (void)cardOwnerBirthDateWithViewController:(UIViewController *)controller success:(void(^)(NSDate *date))success failure:(FailureBlock)failure;

- (void)signingCertWithViewController:(UIViewController *)controller success:(CertDataBlock)success failure:(FailureBlock)failure;
- (void)authenticationCertWithViewController:(UIViewController *)controller success:(CertDataBlock)success failure:(FailureBlock)failure;

- (void)authenticationCertDataWithViewController:(UIViewController *)controller success:(DataSuccessBlock)success failure:(FailureBlock)failure;
- (void)signingCertDataWithViewController:(UIViewController *)controller success:(DataSuccessBlock)success failure:(FailureBlock)failure;

- (void)changePin:(CodeType)type withPuk:(NSString *)puk to:(NSString *)newPin viewController:(UIViewController *)controller success:(VoidBlock)success failure:(FailureBlock)failure;

- (void)changeCode:(CodeType)type withVerifyCode:(NSString *)verify to:(NSString *)newCode viewController:(UIViewController *)controller success:(VoidBlock)success failure:(FailureBlock)failure;

- (void)unblockCode:(CodeType)type withPuk:(NSString *)puk newCode:(NSString *)newCode viewController:(UIViewController *)controller success:(VoidBlock)success failure:(FailureBlock)failure ;

- (void)code:(CodeType)type retryCountWithViewController:(UIViewController *)controller success:(void (^)(NSNumber *))success failure:(FailureBlock)failure;

- (void)addSignature:(MoppLibContainer *)moppContainer controller:(UIViewController *)controller success:(void(^)(MoppLibContainer *container, BOOL signatureWasAdded))success failure:(FailureBlock)failure;
- (void)calculateSignatureFor:(NSData *)hash pin2:(NSString *)pin2 controller:(UIViewController *)controller success:(DataSuccessBlock)success failure:(FailureBlock)failure;

- (void)isCardInserted:(void(^)(BOOL)) completion;
- (BOOL)isReaderConnected;
@end

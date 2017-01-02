//
//  MoppLibPersonalData.h
//  MoppLib
//
//  Created by Katrin Annuk on 28/12/16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MoppLibPersonalData : NSObject

@property (nonatomic, strong) NSString *firstNameLine1;
@property (nonatomic, strong) NSString *firstNameLine2;
@property (nonatomic, strong) NSString *surname;
@property (nonatomic, strong) NSString *sex;
@property (nonatomic, strong) NSString *nationality;
@property (nonatomic, strong) NSString *birthDate;
@property (nonatomic, strong) NSString *personalIdentificationCode;
@property (nonatomic, strong) NSString *documentNumber;
@property (nonatomic, strong) NSString *expiryDate;
@property (nonatomic, strong) NSString *birthPlace;
@property (nonatomic, strong) NSString *dateIssued;
@property (nonatomic, strong) NSString *residentPermitType;
@property (nonatomic, strong) NSString *notes1;
@property (nonatomic, strong) NSString *notes2;
@property (nonatomic, strong) NSString *notes3;
@property (nonatomic, strong) NSString *notes4;

/**
 * Gives full name of card owner
 *
 * @return Full name of card owner
 */
- (NSString *)fullName;
@end

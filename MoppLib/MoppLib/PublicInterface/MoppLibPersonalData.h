//
//  MoppLibPersonalData.h
//  MoppLib
//
/*
 * Copyright 2021 Riigi Infosüsteemi Amet
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

/**
 * Gives full given name of card owner
 *
 * @return Given name of card owner
 */
- (NSString *)givenNames;
@end

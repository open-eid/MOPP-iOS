//
//  MoppLibRoleAddressData.h
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

#import <Foundation/Foundation.h>

@interface MoppLibRoleAddressData : NSObject

@property (nonatomic, strong) NSArray<NSString*> *ROLES;
@property (nonatomic, strong) NSString *CITY;
@property (nonatomic, strong) NSString *STATE;
@property (nonatomic, strong) NSString *COUNTRY;
@property (nonatomic, strong) NSString *ZIP;

- (id) initWithRoles:(NSArray<NSString*> *)ROLES CITY:(NSString *)CITY STATE:(NSString *)STATE COUNTRY:(NSString *)COUNTRY ZIP:(NSString *)ZIP;

@end

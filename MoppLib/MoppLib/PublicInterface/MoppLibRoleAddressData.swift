//
//  MoppLibRoleAddressData.swift
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

import Foundation

@objcMembers
public class MoppLibRoleAddressData: NSObject {

    public var roles: [String]
    public var city: String
    public var state: String
    public var country: String
    public var zip: String

    public init(roles: [String], city: String, state: String, country: String, zip: String) {
        self.roles = roles
        self.city = city
        self.state = state
        self.country = country
        self.zip = zip
        super.init()
    }
}

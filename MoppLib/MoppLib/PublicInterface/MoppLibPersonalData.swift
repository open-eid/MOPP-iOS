//
//  MoppLibPersonalData.swift
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
public class MoppLibPersonalData: NSObject {

    public var givenNames: String = ""
    public var surname: String = ""
    public var sex: String = ""
    public var nationality: String = ""
    public var birthDate: String = ""
    public var personalIdentificationCode: String = ""
    public var documentNumber: String = ""
    public var expiryDate: String = ""
    public var birthPlace: String = ""
    //public var dateIssued: String = ""
    //public var residentPermitType: String = ""
    //public var notes1: String = ""
    //public var notes2: String = ""
    //public var notes3: String = ""
    //public var notes4: String = ""

    /// Returns the full name of the card owner.
    public func fullName() -> String {
        var nameComponents: [String] = []

        if !givenNames.isEmpty {
            nameComponents.append(givenNames)
        }
        if !surname.isEmpty {
            nameComponents.append(surname)
        }

        return nameComponents.joined(separator: " ")
    }
}


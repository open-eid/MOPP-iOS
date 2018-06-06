//
//  AddresseeActions.swift
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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

protocol AddresseeActions {
    func displayAddresseeType(_ addresseetype: String) -> String
    func determineName(addressee: Addressee) -> String
}

extension AddresseeActions {
    
    func determineName(addressee: Addressee) -> String {
        if addressee.givenName == nil {
            return addressee.identifier
        } else {
            return "\(addressee.surname.uppercased()), \(addressee.givenName.uppercased()) ,\(addressee.identifier.uppercased())"
        }
    }
    
    func determineInfo(addressee: Addressee) -> String {
        let addresseeType = displayAddresseeType(addressee.type)
        let validTo = "\(L(LocKey.cryptoValidTo)) \(MoppDateFormatter.shared.ddMMYYYY(toString: addressee.validTo))"
        return "\(addresseeType) (\(validTo))"
    }
    
    func displayAddresseeType(_ addresseetype: String) -> String {
        switch addresseetype {
        case "DIGI-ID":
            return L(.cryptoTypeDigiId)
        case "E-SEAL":
            return L(.cryptoTypeESeal)
        default:
            return L(.cryptoTypeIdCard)
        }
    }
    
}

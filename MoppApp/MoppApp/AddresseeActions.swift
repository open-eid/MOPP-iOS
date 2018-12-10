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
    func displayAddresseeType(_ policyIdentifiers: [String]) -> String
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
        let policyIdentifiers = addressee.policyIdentifiers as? [String] ?? []
        let addresseeType = displayAddresseeType(policyIdentifiers)
        let validTo = "\(L(LocKey.cryptoValidTo)) \(MoppDateFormatter.shared.ddMMYYYY(toString: addressee.validTo))"
        return "\(addresseeType) (\(validTo))"
    }
    
    func displayAddresseeType(_ policyIdentifiers: [String]) -> String {
        if policyIdentifiers == [] {
            return L(.cryptoTypeUnknown)
        }
        for pi in policyIdentifiers {
            if pi.hasPrefix("1.3.6.1.4.1.10015.1.1")
                || pi.hasPrefix("1.3.6.1.4.1.51361.1.1.1") {
                return L(.cryptoTypeIdCard)
            }
            else if pi.hasPrefix("1.3.6.1.4.1.10015.1.2")
                || pi.hasPrefix("1.3.6.1.4.1.51361.1.1")
                || pi.hasPrefix("1.3.6.1.4.1.51455.1.1") {
                return L(.cryptoTypeDigiId)
            }
            else if pi.hasPrefix("1.3.6.1.4.1.10015.1.3")
                || pi.hasPrefix("1.3.6.1.4.1.10015.11.1") {
                return L(.cryptoTypeMobileId)
            }
            else if pi.hasPrefix("1.3.6.1.4.1.10015.7.3")
                || pi.hasPrefix("1.3.6.1.4.1.10015.7.1")
                || pi.hasPrefix("1.3.6.1.4.1.10015.2.1") {
                return L(.cryptoTypeESeal)
            }
        }
        return L(.cryptoTypeUnknown)
    }
    
}

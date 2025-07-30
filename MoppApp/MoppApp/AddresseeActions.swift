//
//  AddresseeActions.swift
//  MoppApp
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
import ASN1Decoder
import CryptoLib

protocol AddresseeActions {
    func displayAddresseeType(_ type: X509Certificate.CertType?) -> String
    func determineName(addressee: Addressee) -> String
}

extension AddresseeActions {

    func determineName(addressee: Addressee) -> String {
        if addressee.givenName == nil {
            return "\(addressee.identifier ?? ""), \(addressee.serialNumber ?? "")"
        } else {
            return "\(addressee.surname.uppercased()), \(addressee.givenName.uppercased()), \(addressee.identifier.uppercased())"
        }
    }

    func determineInfo(addressee: Addressee) -> String {
        let x509 = try? X509Certificate(der: addressee.cert)
        let addresseeType = displayAddresseeType(x509?.certType())
        let validTo = "\(L(LocKey.cryptoValidTo)) \(MoppDateFormatter.shared.ddMMYYYY(toString: x509?.notAfter ?? Date()))"
        return "\(addresseeType) (\(validTo))"
    }

    func displayAddresseeType(_ type: X509Certificate.CertType?) -> String {
        switch type {
        case .IDCardType:
            return L(.cryptoTypeIdCard)
        case .DigiIDType:
            return L(.cryptoTypeDigiId)
        case .MobileIDType:
            return L(.cryptoTypeMobileId)
        case .ESealType:
            return L(.cryptoTypeESeal)
        default:
            return L(.cryptoTypeUnknown)
        }
    }
    
}

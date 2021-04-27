//
//  CertificateRequestParameters.swift
//  SkSigningLib
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

import Foundation

// MARK: - CertificateRequestParameters
public struct CertificateRequestParameters : Codable {
    let relyingPartyUUID : String
    let relyingPartyName : String
    let phoneNumber : String
    let nationalIdentityNumber : String
    
    public enum CodingKeys: String, CodingKey {
        case relyingPartyUUID
        case relyingPartyName
        case phoneNumber
        case nationalIdentityNumber
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        relyingPartyUUID = try values.decode(String.self, forKey: .relyingPartyUUID)
        relyingPartyName = try values.decode(String.self, forKey: .relyingPartyName)
        phoneNumber = try values.decode(String.self, forKey: .phoneNumber)
        nationalIdentityNumber = try values.decode(String.self, forKey: .nationalIdentityNumber)
    }
    
    public init(relyingPartyUUID: String, relyingPartyName: String, phoneNumber: String, nationalIdentityNumber: String) throws {
        self.relyingPartyUUID = relyingPartyUUID
        self.relyingPartyName = relyingPartyName
        self.phoneNumber = phoneNumber
        self.nationalIdentityNumber = nationalIdentityNumber
    }
}

//
//  SessionRequestParameters.swift
//  SkSigningLib
//
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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

// MARK: - SessionRequestParameters
public struct SessionRequestParameters: Codable {
    let relyingPartyName: String
    let relyingPartyUUID: String
    let phoneNumber: String
    let nationalIdentityNumber: String
    let hash: String
    let hashType: String
    let language: String
    let displayText: String?
    let displayTextFormat: String?
    
    var asData: Data {
            return #"""
    { "nationalIdentityNumber":"\#(nationalIdentityNumber)","hash":"\#(hash)","relyingPartyName":"\#(relyingPartyName)","displayTextFormat":"\#(displayTextFormat ?? "GSM-7")","displayText":"\#(displayText ?? "")","hashType":"\#(hashType)","language":"\#(language)","relyingPartyUUID":"\#(relyingPartyUUID)","phoneNumber":"\#(phoneNumber)" }
    """#.data(using: .utf8) ?? Data()
    }
    
    public enum CodingKeys: String, CodingKey {
        case relyingPartyName
        case relyingPartyUUID
        case phoneNumber
        case nationalIdentityNumber
        case hash
        case hashType
        case language
        case displayText
        case displayTextFormat
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        relyingPartyName = try values.decode(String.self, forKey: .relyingPartyName)
        relyingPartyUUID = try values.decode(String.self, forKey: .relyingPartyUUID)
        phoneNumber = try values.decode(String.self, forKey: .phoneNumber)
        nationalIdentityNumber = try values.decode(String.self, forKey: .nationalIdentityNumber)
        hash = try values.decode(String.self, forKey: .hash)
        hashType = try values.decode(String.self, forKey: .hashType)
        language = try values.decode(String.self, forKey: .language)
        displayText = try values.decode(String.self, forKey: .displayText)
        displayTextFormat = try values.decode(String.self, forKey: .displayTextFormat)
    }
    
    public init(relyingPartyName: String, relyingPartyUUID: String, phoneNumber: String, nationalIdentityNumber: String, hash: String, hashType: String, language: String, displayText: String, displayTextFormat: String) throws {
        self.relyingPartyName = relyingPartyName
        self.relyingPartyUUID = relyingPartyUUID
        self.phoneNumber = phoneNumber
        self.nationalIdentityNumber = nationalIdentityNumber
        self.hash = hash
        self.hashType = hashType
        self.language = language
        self.displayText = displayText
        self.displayTextFormat = displayTextFormat
    }
}

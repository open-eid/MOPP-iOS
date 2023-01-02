/*
 * SkSigningLib - SIDSignatureRequestParameters.swift
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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

public struct SIDSignatureRequestParametersProperties: Codable {
    public let vcChoice: Bool

    public enum CodingKeys: String, CodingKey {
        case vcChoice
    }

    public init(vcChoice: Bool) {
        self.vcChoice = vcChoice
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        vcChoice = try values.decode(Bool.self, forKey: .vcChoice)
    }
}

// MARK: - SIDSignatureRequestParameters
public struct SIDSignatureRequestParameters: Codable {
    let relyingPartyName: String
    let relyingPartyUUID: String
    let hash: String
    let hashType: String
    let displayText: String?
    let requestProperties: SIDSignatureRequestParametersProperties?
    
    var asData: Data {
        return #"""
{"requestProperties":{"vcChoice":\#(requestProperties?.vcChoice ?? true)},"hash":"\#(hash)","hashType":"\#(hashType)","displayText":"\#(displayText ?? "")","relyingPartyName":"\#(relyingPartyName)","relyingPartyUUID":"\#(relyingPartyUUID)"}
"""#.data(using: .utf8) ?? Data()
    }

    public enum CodingKeys: String, CodingKey {
        case relyingPartyName
        case relyingPartyUUID
        case hash
        case hashType
        case displayText
        case requestProperties
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        relyingPartyName = try values.decode(String.self, forKey: .relyingPartyName)
        relyingPartyUUID = try values.decode(String.self, forKey: .relyingPartyUUID)
        hash = try values.decode(String.self, forKey: .hash)
        hashType = try values.decode(String.self, forKey: .hashType)
        displayText = try values.decodeIfPresent(String.self, forKey: .displayText)
        requestProperties = try values.decodeIfPresent(SIDSignatureRequestParametersProperties.self, forKey: .requestProperties)
    }

    public init(relyingPartyName: String, relyingPartyUUID: String, hash: String, hashType: String, displayText: String? = nil, requestProperties: SIDSignatureRequestParametersProperties? = nil) {
        self.relyingPartyName = relyingPartyName
        self.relyingPartyUUID = relyingPartyUUID
        self.hash = hash
        self.hashType = hashType
        self.displayText = displayText
        self.requestProperties = requestProperties
    }

    public init(relyingPartyName: String, relyingPartyUUID: String,hash: String, hashType: String, displayText: String, vcChoice: Bool) {
        self.init(relyingPartyName: relyingPartyName, relyingPartyUUID: relyingPartyUUID, hash: hash, hashType: hashType, displayText: displayText, requestProperties: SIDSignatureRequestParametersProperties(vcChoice: vcChoice))
    }
}

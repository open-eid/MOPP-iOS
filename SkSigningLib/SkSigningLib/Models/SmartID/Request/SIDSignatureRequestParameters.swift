/*
 * SkSigningLib - SIDSignatureRequestParameters.swift
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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

public struct SIDSignatureRequestAllowedInteractionsOrder: Codable {
    public let type: String
    public let displayText200: String
    
    public enum CodingKeys: String, CodingKey {
        case type
        case displayText200
    }

    public init(type: String, displayText: String) {
        self.type = type
        self.displayText200 = displayText
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        displayText200 = try values.decode(String.self, forKey: .displayText200)
    }
}

// MARK: - SIDSignatureRequestParameters
public class SIDSignatureRequestParameters: Codable {
    let relyingPartyName: String
    let relyingPartyUUID: String
    let hash: String
    let hashType: String
    
    public init() {
        self.relyingPartyName = ""
        self.relyingPartyUUID = ""
        self.hash = ""
        self.hashType = ""
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        relyingPartyName = try values.decode(String.self, forKey: .relyingPartyName)
        relyingPartyUUID = try values.decode(String.self, forKey: .relyingPartyUUID)
        hash = try values.decode(String.self, forKey: .hash)
        hashType = try values.decode(String.self, forKey: .hashType)
    }
    
    public init(relyingPartyName: String, relyingPartyUUID: String, hash: String, hashType: String) {
        self.relyingPartyName = relyingPartyName
        self.relyingPartyUUID = relyingPartyUUID
        self.hash = hash
        self.hashType = hashType
    }
}

// MARK: - SIDSignatureRequestParametersV1
public class SIDSignatureRequestParametersV1: SIDSignatureRequestParameters {
    let displayText: String?
    let requestProperties: SIDSignatureRequestParametersProperties?
    
    var asData: Data {
        return #"""
{"requestProperties":{"vcChoice":\#(requestProperties?.vcChoice ?? true)},"hash":"\#(hash)","hashType":"\#(hashType)","displayText":"\#(displayText ?? "")","relyingPartyName":"\#(relyingPartyName)","relyingPartyUUID":"\#(relyingPartyUUID)"}
"""#.data(using: .utf8) ?? Data()
    }

    public enum CodingKeys: String, CodingKey {
        case displayText
        case requestProperties
    }
    
    public override init() {
        self.displayText = nil
        self.requestProperties = nil
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        displayText = try values.decodeIfPresent(String.self, forKey: .displayText)
        requestProperties = try values.decodeIfPresent(SIDSignatureRequestParametersProperties.self, forKey: .requestProperties)
        super.init()
    }

    public init(relyingPartyName: String, relyingPartyUUID: String, hash: String, hashType: String, displayText: String? = nil, requestProperties: SIDSignatureRequestParametersProperties? = nil) {
        self.displayText = displayText
        self.requestProperties = requestProperties
        super.init(relyingPartyName: relyingPartyName, relyingPartyUUID: relyingPartyUUID, hash: hash, hashType: hashType)
    }

    public convenience init(relyingPartyName: String, relyingPartyUUID: String,hash: String, hashType: String, displayText: String, vcChoice: Bool) {
        self.init(relyingPartyName: relyingPartyName, relyingPartyUUID: relyingPartyUUID, hash: hash, hashType: hashType, displayText: displayText, requestProperties: SIDSignatureRequestParametersProperties(vcChoice: vcChoice))
    }
}

// MARK: - SIDSignatureRequestParametersV2
public class SIDSignatureRequestParametersV2: SIDSignatureRequestParameters {
    let allowedInteractionsOrder: SIDSignatureRequestAllowedInteractionsOrder?
    
    var asData: Data {
        return #"""
{"allowedInteractionsOrder": [{"type":"\#(allowedInteractionsOrder?.type ?? "")","displayText200":"\#(allowedInteractionsOrder?.displayText200 ?? "")"}],"hash":"\#(hash)","hashType":"\#(hashType)","relyingPartyName":"\#(relyingPartyName)","relyingPartyUUID":"\#(relyingPartyUUID)"}
"""#.data(using: .utf8) ?? Data()
    }

    public enum CodingKeys: String, CodingKey {
        case allowedInteractionsOrder
    }

    public override init() {
        self.allowedInteractionsOrder = nil
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        allowedInteractionsOrder = try values.decodeIfPresent(SIDSignatureRequestAllowedInteractionsOrder.self, forKey: .allowedInteractionsOrder)
        super.init()
    }
    
    public init(relyingPartyName: String, relyingPartyUUID: String, hash: String, hashType: String, allowedInteractionsOrder: SIDSignatureRequestAllowedInteractionsOrder? = nil) {
        self.allowedInteractionsOrder = allowedInteractionsOrder
        super.init(relyingPartyName: relyingPartyName, relyingPartyUUID: relyingPartyUUID, hash: hash, hashType: hashType)
    }

    public convenience init(relyingPartyName: String, relyingPartyUUID: String, hash: String, hashType: String, type: String, displayText: String) {
        self.init(relyingPartyName: relyingPartyName, relyingPartyUUID: relyingPartyUUID, hash: hash, hashType: hashType, allowedInteractionsOrder: SIDSignatureRequestAllowedInteractionsOrder(type: type, displayText: displayText))
    }
}

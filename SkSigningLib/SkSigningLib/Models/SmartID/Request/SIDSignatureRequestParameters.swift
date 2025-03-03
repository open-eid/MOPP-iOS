/*
 * SkSigningLib - SIDSignatureRequestParameters.swift
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

public struct SIDSignatureRequestParametersProperties: Encodable {
    let vcChoice: Bool
}

public struct SIDSignatureRequestAllowedInteractionsOrder: Encodable {
    let type: String
    let displayText200: String

    public init(type: String, displayText: String) {
        self.type = type
        self.displayText200 = displayText
    }
}

public struct SIDSignatureRequestParameters: Encodable {
    let relyingPartyName: String
    let relyingPartyUUID: String
    let hash: Data
    let hashType: String
    let allowedInteractionsOrder: SIDSignatureRequestAllowedInteractionsOrder?

    public init(relyingPartyName: String = "", relyingPartyUUID: String = "", hash: Data = Data(), hashType: String = "", allowedInteractionsOrder: SIDSignatureRequestAllowedInteractionsOrder? = nil) {
        self.relyingPartyName = relyingPartyName
        self.relyingPartyUUID = relyingPartyUUID
        self.hash = hash
        self.hashType = hashType
        self.allowedInteractionsOrder = allowedInteractionsOrder
    }

    var asData: Data {
        return #"""
{"allowedInteractionsOrder": [{"type":"\#(allowedInteractionsOrder?.type ?? "")","displayText200":"\#(allowedInteractionsOrder?.displayText200 ?? "")"}],"hash":"\#(hash.base64EncodedString())","hashType":"\#(hashType)","relyingPartyName":"\#(relyingPartyName)","relyingPartyUUID":"\#(relyingPartyUUID)"}
"""#.data(using: .utf8) ?? Data()
    }
}

/*
 * SkSigningLib - SIDSessionStatusResponse.swift
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

public enum SIDSessionStatusResponseState: String, Decodable {
    case RUNNING
    case COMPLETE
}

public enum SIDSessionStatusResponseCode: String, Decodable {
    case OK
    case USER_REFUSED
    case TIMEOUT
    case DOCUMENT_UNUSABLE
    case WRONG_VC
}

public struct SIDSessionStatusResponseResult: Decodable {
    public let endResult: SIDSessionStatusResponseCode
    public let documentNumber: String?

    public enum CodingKeys: String, CodingKey {
        case endResult
        case documentNumber
    }

    public init(endResult: SIDSessionStatusResponseCode, documentNumber: String? = nil) {
        self.endResult = endResult
        self.documentNumber = documentNumber
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        endResult = try values.decode(SIDSessionStatusResponseCode.self, forKey: .endResult)
        documentNumber = try values.decodeIfPresent(String.self, forKey: .documentNumber)
    }
}

public struct SIDSessionStatusResponseCertificate: Decodable {
    public let value: String
    public let certificateLevel: String

    public enum CodingKeys: String, CodingKey {
        case value
        case certificateLevel
    }

    public init(value: String, certificateLevel: String) {
        self.value = value
        self.certificateLevel = certificateLevel
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        value = try values.decode(String.self, forKey: .value)
        certificateLevel = try values.decode(String.self, forKey: .certificateLevel)
    }
}

public struct SIDSessionStatusResponseSignature: Decodable {
    public let value: String
    public let algorithm: String

    public enum CodingKeys: String, CodingKey {
        case value
        case algorithm
    }

    public init(value: String, algorithm: String) {
        self.value = value
        self.algorithm = algorithm
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        value = try values.decode(String.self, forKey: .value)
        algorithm = try values.decode(String.self, forKey: .algorithm)
    }
}

public struct SIDSessionStatusResponse: Decodable {
    public let state: SIDSessionStatusResponseState
    public let result: SIDSessionStatusResponseResult?
    public let signature: SIDSessionStatusResponseSignature?
    public let cert: SIDSessionStatusResponseCertificate?

    public enum CodingKeys: String, CodingKey {
        case state
        case result
        case signature
        case cert
    }

    public init(state: SIDSessionStatusResponseState,
                result: SIDSessionStatusResponseResult? = nil,
                signature: SIDSessionStatusResponseSignature? = nil,
                cert: SIDSessionStatusResponseCertificate? = nil) {
        self.state = state
        self.result = result
        self.signature = signature
        self.cert = cert
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        state = try values.decode(SIDSessionStatusResponseState.self, forKey: .state)
        result = try values.decodeIfPresent(SIDSessionStatusResponseResult.self, forKey: .result)
        signature = try values.decodeIfPresent(SIDSessionStatusResponseSignature.self, forKey: .signature)
        cert = try values.decodeIfPresent(SIDSessionStatusResponseCertificate.self, forKey: .cert)
    }
}

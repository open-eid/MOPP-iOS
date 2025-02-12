/*
 * SkSigningLib - SIDSessionStatusResponse.swift
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

public enum SIDSessionStatusResponseState: String, Decodable {
    case RUNNING
    case COMPLETE
}

public enum SIDSessionStatusResponseCode: String, Decodable {
    case OK
    case USER_REFUSED
    case USER_REFUSED_DISPLAYTEXTANDPIN
    case USER_REFUSED_VC_CHOICE
    case USER_REFUSED_CONFIRMATIONMESSAGE
    case USER_REFUSED_CONFIRMATIONMESSAGE_WITH_VC_CHOICE
    case USER_REFUSED_CERT_CHOICE
    case REQUIRED_INTERACTION_NOT_SUPPORTED_BY_APP
    case TIMEOUT
    case DOCUMENT_UNUSABLE
    case WRONG_VC
}

public struct SIDSessionStatusResponseResult: Decodable {
    public let endResult: SIDSessionStatusResponseCode
    public let documentNumber: String?
}

public struct SIDSessionStatusResponseCertificate: Decodable {
    public let value: Data
    public let certificateLevel: String
}

public struct SIDSessionStatusResponseSignature: Decodable {
    public let value: Data
    public let algorithm: String
}

public struct SIDSessionStatusResponse: Decodable {
    public let state: SIDSessionStatusResponseState
    public let result: SIDSessionStatusResponseResult?
    public let signature: SIDSessionStatusResponseSignature?
    public let cert: SIDSessionStatusResponseCertificate?
}

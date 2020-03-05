//
//  SessionStatusResponse.swift
//  SkSigningLib
/*
 * Copyright 2020 Riigi Infosüsteemide Amet
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

public enum SessionResponseState: String, Decodable {
    case RUNNING
    case COMPLETE
}

public struct SessionStatusResponse: Decodable {
    let state: SessionResponseState
    let result: String?
    let signature: SessionResponseSignature?
    let cert: String?
    let time: String?
    let traceId: String?
    
    public enum CodingKeys: String, CodingKey {
        case state
        case result
        case signature
        case cert
        case time
        case traceId
    }
    
    public init(state: SessionResponseState,
                result: String? = nil,
                signature: SessionResponseSignature? = nil,
                cert: String? = nil,
                time: String? = nil,
                traceId: String? = nil) {
        
        self.state = state
        self.result = result
        self.signature = signature
        self.cert = cert
        self.time = time
        self.traceId = traceId
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        state = try values.decode(SessionResponseState.self, forKey: .state)
        result = try values.decodeIfPresent(String.self, forKey: .result)
        signature = try values.decodeIfPresent(SessionResponseSignature.self, forKey: .signature)
        cert = try values.decodeIfPresent(String.self, forKey: .cert)
        time = try values.decodeIfPresent(String.self, forKey: .time)
        traceId = try values.decodeIfPresent(String.self, forKey: .traceId)
    }
}

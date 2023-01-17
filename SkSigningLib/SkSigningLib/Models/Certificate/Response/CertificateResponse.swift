//
//  CertificateResponse.swift
//  SkSigningLib
/*
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


public struct CertificateResponse: Decodable {
    public let result: ResponseResult?
    public let cert: String?
    public let time: String?
    public let traceId: String?
    public let error: String?
    
    public enum CodingKeys: String, CodingKey {
        case result
        case cert
        case time
        case traceId
        case error
    }
    
    public init(result: ResponseResult? = nil,
                cert: String? = nil,
                time: String? = nil,
                traceId: String? = nil,
                error: String? = nil) {
        
        self.result = result
        self.cert = cert
        self.time = time
        self.traceId = traceId
        self.error = error
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        result = try values.decodeIfPresent(ResponseResult.self, forKey: .result)
        cert = try values.decodeIfPresent(String.self, forKey: .cert)
        time = try values.decodeIfPresent(String.self, forKey: .time)
        traceId = try values.decodeIfPresent(String.self, forKey: .traceId)
        error = try values.decodeIfPresent(String.self, forKey: .error)
    }
}

public enum ResponseResult: String, Decodable {
    case OK
    case NOT_FOUND
    case NOT_ACTIVE
}

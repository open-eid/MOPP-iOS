//
//  SessionResponse.swift
//  SkSigningLib
//
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

public struct SessionResponse: Decodable {
    public let sessionID: String?
    public let time: String?
    public let traceId: String?
    public let error: String?
    
    public enum CodingKeys: String, CodingKey {
        case sessionID
        case time
        case traceId
        case error
    }
    
    public init(sessionID: String? = nil,
                time: String? = nil,
                traceId: String? = nil,
                error: String? = nil) {
        
        self.sessionID = sessionID
        self.time = time
        self.traceId = traceId
        self.error = error
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sessionID = try values.decodeIfPresent(String.self, forKey: .sessionID)
        time = try values.decodeIfPresent(String.self, forKey: .time)
        traceId = try values.decodeIfPresent(String.self, forKey: .traceId)
        error = try values.decodeIfPresent(String.self, forKey: .error)
    }
}

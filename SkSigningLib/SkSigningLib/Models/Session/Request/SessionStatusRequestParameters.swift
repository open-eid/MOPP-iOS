//
//  SessionStatusRequestParameters.swift
//  SkSigningLib
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

// MARK: - SessionStatusRequestParameters
public struct SessionStatusRequestParameters: Codable {
    public let sessionId: String
    public let timeoutMs: Int?
    
    public enum CodingKeys: String, CodingKey {
        case sessionId
        case timeoutMs
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try values.decode(String.self, forKey: .sessionId)
        timeoutMs = try values.decodeIfPresent(Int.self, forKey: .timeoutMs) ?? Constants.defaultTimeoutMs
    }
    
    public init(sessionId: String) throws {
        self.sessionId = sessionId
        self.timeoutMs = Constants.defaultTimeoutMs
    }
    
    public init(sessionId: String, timeoutMs: Int?) throws {
        self.sessionId = sessionId
        self.timeoutMs = timeoutMs ?? Constants.defaultTimeoutMs
    }
}

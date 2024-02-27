//
//  Encoder.swift
//  SkSigningLib
/*
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

class EncoderDecoder {
    
    func encode<T: Encodable>(data: T) -> Data {
        do {
            return try JSONEncoder().encode(data)
        } catch let error {
            Logging.errorLog(forMethod: "encode", error: error, extraInfo: "Unable to encode data")
        }
        
        return Data()
    }
    
    func decode<T: Decodable>(data: Data, completionHandler: @escaping (T) -> ()) {
        do {
            completionHandler(try JSONDecoder().decode(T.self, from: data))
        } catch let error {
            Logging.errorLog(forMethod: "decode", error: error, extraInfo: "Unable to decode data")
        }
    }
    
    
}


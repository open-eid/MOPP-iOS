//
//  ControlCode.swift
//  SkSigningLib
//
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

public class ControlCode {
    
    public static let shared: ControlCode = ControlCode()
    
    public func getVerificationCode(hash: Data) -> String? {
        guard !hash.isEmpty else {
            Logging.errorLog(forMethod: "RIA.MobileID - getVerificationCode", error: nil, extraInfo: "Unable to get hash")
            return nil
        }
        
        let verificationCode = ((0xFC & Int(hash.first!)) << 5) | (Int(hash.last!) & 0x7F)
        let verificationCodeAsString = String(format: "%04d", verificationCode)
        
        Logging.log(forMethod: "RIA.MobileID - getVerificationCode", info: "Mobile-ID verification code: \(verificationCodeAsString)")
        
        return verificationCodeAsString
    }
}


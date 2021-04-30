//
//  ControlCode.swift
//  SkSigningLib
//
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

public class ControlCode {
    
    public static let shared: ControlCode = ControlCode()
    
    public func getVerificationCode(hash: Array<Int>) -> String? {
        guard !hash.isEmpty else {
            return nil
        }
        
        let verificationCode: Int = ((0xFC & hash.first!) << 5) | (hash.last! & 0x7F)
        
        let verificationCodeAsString: String = addLeadingZerosIfNeeded(verificationCode: String(verificationCode))
        
        print("Mobile-ID verification code: \(verificationCodeAsString)")
        
        return verificationCodeAsString
    }
    
    private func addLeadingZerosIfNeeded(verificationCode: String) -> String {
        if verificationCode.count == 3 {
            return "0\(verificationCode)"
        } else if verificationCode.count == 2 {
            return "00\(verificationCode)"
        } else if verificationCode.count == 1 {
            return "000\(verificationCode)"
        }
        
        return verificationCode
    }
}


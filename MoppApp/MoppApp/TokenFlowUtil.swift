//
//  TokenFlowUtil.swift
//  MoppApp
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

class TokenFlowUtil {

    static let countryCodes = ["372", "370"]

    static func isPhoneNumberInvalid(text: String) -> Bool {
        let numberNoCountryCode = text.dropFirst(3)
        return numberNoCountryCode.count < 7
    }

    static func isCountryCodeValid(text: String) -> Bool {
        let countryCodeExists = countryCodes.filter({ text.starts(with: $0) }).first
        return countryCodeExists != nil
    }

    static func isPersonalCodeInvalid(text: String) -> Bool {
        return text.count < 11
    }

    static func isPinCodeValid(text: String, pinType: IdCardCodeName) -> Bool {
        if pinType.rawValue == "PIN1" {
            return text.count >= IdCardCodeLengthLimits.pin1Minimum.rawValue
        }
        return text.count >= IdCardCodeLengthLimits.pin2Minimum.rawValue
    }
}

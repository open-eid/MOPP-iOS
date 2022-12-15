//
//  PersonalCodeValidator.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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

protocol PersonalCodeValidating {
    static func isPersonalCodeValid(personalCode: String) -> Bool
    static func isPersonalCodeNumeric(personalCode: String) -> Bool
    static func isBirthDateValid(personalCode: String) -> Bool
    static func isChecksumValid(personalCode: String) -> Bool
    static func isPersonalCodeLengthValid(personalCode: String) -> Bool
}

struct PersonalCodeValidator: PersonalCodeValidating {
    
    static func isPersonalCodeValid(personalCode: String) -> Bool {
        return (isPersonalCodeLengthValid(personalCode: personalCode) && isBirthDateValid(personalCode: personalCode) && isChecksumValid(personalCode: personalCode)) || (isPersonalCodeLengthValid(personalCode: personalCode) && isMobileIdTestCode(personalCode: personalCode))
    }
    
    static func isPersonalCodeNumeric(personalCode: String) -> Bool {
        return personalCode.isNumeric
    }
    
    static func isBirthDateValid(personalCode: String) -> Bool {
        guard isPersonalCodeNumeric(personalCode: personalCode) else { return false }
        
        guard let firstNumber = personalCode.first?.wholeNumberValue else { return false }
        
        var century = 0;
        switch(Int(firstNumber)) {
        case 1, 2: century = 1800; break
        case 3, 4: century = 1900; break
        case 5, 6: century = 2000; break
        case 7, 8: century = 2100; break
        default:
            printLog("Invalid number: \(firstNumber)")
            return false
        }
        
        guard let yearCode = personalCode.substr(offset: 1, count: 2), let year = Int(yearCode) else { return false }
        
        guard let month = Int(personalCode.substr(offset: 3, count: 2) ?? "0"), month != 0 else { return false }
        
        guard let day = Int(personalCode.substr(offset: 5, count: 2) ?? "0"), day != 0 else { return false }
        
        var birthDateComponents = DateComponents()
        birthDateComponents.year = year + century
        birthDateComponents.month = month
        birthDateComponents.day = day
        birthDateComponents.timeZone = TimeZone.current
        
        return birthDateComponents.isValidDate(in: Calendar(identifier: .gregorian))
    }
    
    static func isChecksumValid(personalCode: String) -> Bool {
        var sum1 = 0
        var sum2 = 0
        var i = 0, pos1 = 1, pos2 = 3
        while i < 10 {
            sum1 += (Int(personalCode.substr(offset: i, count: 1) ?? "0") ?? 0) * pos1;
            sum2 += (Int(personalCode.substr(offset: i, count: 1) ?? "0") ?? 0) * pos2;
            pos1 = pos1 == 9 ? 1 : pos1 + 1;
            pos2 = pos2 == 9 ? 1 : pos2 + 1;
            
            i += 1
        }
        
        var result = 0
        
        result = sum1 % 11
        if result >= 10 {
            result = sum2 % 11
        }
        
        if result >= 10 {
            result = 0
        }
        
        guard let personalCodeLastNumber = personalCode.last?.wholeNumberValue else { return false }
        
        return personalCodeLastNumber == result
    }
    
    static func isPersonalCodeLengthValid(personalCode: String) -> Bool {
        return personalCode.count == 11
    }
    
    private static func isMobileIdTestCode(personalCode: String) -> Bool {
        let testNumbers = [
        "14212128020",
        "14212128021",
        "14212128022",
        "14212128023",
        "14212128024",
        "14212128025",
        "14212128026",
        "14212128027",
        "38002240211",
        "14212128029"
        ]

        return testNumbers.contains(personalCode)
    }
}

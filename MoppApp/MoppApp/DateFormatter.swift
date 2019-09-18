//
//  DateFormatter.swift
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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

class MoppDateFormatter {

    var ddMMYYYYDateFormatter: DateFormatter = {
        let result = DateFormatter()
            result.dateFormat = "dd.MM.YYYY"
        return result
    }()
    var hHmmssddMMYYYYDateFormatter: DateFormatter = {
        let result = DateFormatter()
            result.dateFormat = "HH:mm:ss dd.MM.YYYY"
        return result
    }()
    var ddMMMDateFormatter: DateFormatter = {
        let result = DateFormatter()
            result.dateFormat = "dd. MMM"
        return result
    }()
    var relativeDateFormatter: DateFormatter = {
        let result = DateFormatter()
            result.dateStyle = .short
            result.doesRelativeDateFormatting = true
        return result
    }()
    var nonRelativeDateFormatter: DateFormatter = {
        let result = DateFormatter()
            result.dateStyle = .short
            result.doesRelativeDateFormatting = false
        return result
    }()

    public static let shared = MoppDateFormatter()

    func ddMMYYYY(toString date: Date) -> String {
        return ddMMYYYYDateFormatter.string(from: date)
    }

    // 02.03.2015
    func ddMMYYYY(toDate string: String) -> Date {
        return ddMMYYYYDateFormatter.date(from: string) ?? Date()
    }

    // 17:32:06 02.03.2015
    func hHmmssddMMYYYY(toString date: Date) -> String {
        return hHmmssddMMYYYYDateFormatter.string(from: date)
    }

    // 21. Nov OR relative string "Today" etc.
    func date(toRelativeString date: Date) -> String {
        let relativeString: String = relativeDateFormatter.string(from: date)
        let nonRelativeString: String = nonRelativeDateFormatter.string(from: date)
        if relativeString == nonRelativeString {
            return ddMMMDateFormatter.string(from: date)
            // No relative date available, use custom format.
        }
        else {
            return relativeString
            // Return relative date.
        }
    }

    func utcTimestampString(toLocalTime date: Date) -> String {
        let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss dd.MM.YYYY"
            dateFormatter.timeZone = NSTimeZone.local
        return dateFormatter.string(from: date)
    }
}

//
//  DateFormatter.swift
//  MoppApp
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
    var fullDateFormatter: DateFormatter = {
        let result = DateFormatter()
            result.dateFormat = "EEEE, d MMMM yyyy HH:mm:ss Z"
        return result
    }()

    public static let shared = MoppDateFormatter()

    func ddMMYYYY(toString date: Date) -> String {
        return handleTimeFormats(date: date, dateFormat: ddMMYYYYDateFormatter.dateFormat)
    }

    // 02.03.2015
    func ddMMYYYY(toDate string: String) -> Date {
        return ddMMYYYYDateFormatter.date(from: handleTimeFormats(
            date: ddMMYYYYDateFormatter.date(from: string) ?? Date(),
            dateFormat: ddMMYYYYDateFormatter.dateFormat)) ?? Date()
    }

    // 17:32:06 02.03.2015
    func hHmmssddMMYYYY(toString date: Date) -> String {
        return handleTimeFormats(date: date, dateFormat: hHmmssddMMYYYYDateFormatter.dateFormat)
    }

    // 21. Nov OR relative string "Today" etc.
    func date(toRelativeString date: Date) -> String {
        let relativeString: String = relativeDateFormatter.string(from: date)
        let nonRelativeString: String = nonRelativeDateFormatter.string(from: date)
        if relativeString == nonRelativeString {
            return handleTimeFormats(date: date, dateFormat: ddMMMDateFormatter.dateFormat)
            // No relative date available, use custom format.
        }
        else {
            return handleTimeFormats(date: date, dateFormat: relativeDateFormatter.dateFormat)
            // Return relative date.
        }
    }

    func utcTimestampString(toLocalTime date: Date) -> String {
        let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss dd.MM.YYYY"
            dateFormatter.timeZone = NSTimeZone.local
        return handleTimeFormats(date: date, dateFormat: dateFormatter.dateFormat)
    }
    
    func dateToString(date: Date?, _ withTime: Bool = true) -> String {
        guard let date = date else { return "" }
        
        let formatter = DateFormatter()
        if withTime {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        } else {
            formatter.dateFormat = "yyyy-MM-dd"
        }
        
        let formattedDateTime = formatter.date(from: formatter.string(from: date))
        if withTime {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        } else {
            formatter.dateFormat = "yyyy-MM-dd"
        }
        return handleTimeFormats(date: formattedDateTime!, dateFormat: formatter.dateFormat)
    }
    
    func stringToDate(dateString: String?) -> Date {
        guard let dateString = dateString, !dateString.isEmpty else { return Date() }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        let date = dateFormatter.date(from: dateString) ?? Date()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd jj:mm:ss Z")
        let convertedDateString = dateFormatter.string(from: date)
        return dateFormatter.date(from: convertedDateString) ?? Date()
    }
    
    func handleTimeFormats(date: Date, dateFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let universalHourFormat = dateFormat.replacingOccurrences(of: "hh", with: "jj").replacingOccurrences(of: "HH", with: "jj")
        dateFormatter.setLocalizedDateFormatFromTemplate(universalHourFormat)
        return dateFormatter.string(from: date)
    }
    
    func getDateTimeInUTCTimeZone(date: Date?) -> String {
        guard let date = date else { return "" }
        let formattedDateFormatter = DateFormatter()
        formattedDateFormatter.timeZone = TimeZone.init(identifier: "UTC")
        formattedDateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss Z"
        return formattedDateFormatter.string(from: date)
    }
    
    func getDateTimeInCurrentTimeZone(date: Date?) -> String {
        guard let date = date else { return "" }
        let formattedDateFormatter: DateFormatter = DateFormatter()
        formattedDateFormatter.timeZone = TimeZone.autoupdatingCurrent
        formattedDateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss Z"
        return formattedDateFormatter.string(from: date)
    }
    
    func getFullDateTimeInCurrentTimeZone(date: Date?) -> String? {
        if let requestedDate = date {
            let formattedDateFormatter: DateFormatter = fullDateFormatter
            formattedDateFormatter.timeZone = TimeZone.autoupdatingCurrent
            
            return formattedDateFormatter.string(from: requestedDate)
        }
        
        return nil
        
    }
}

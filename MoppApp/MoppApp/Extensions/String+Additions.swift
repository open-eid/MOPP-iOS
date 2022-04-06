//
//  NSString+Additions.swift
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

extension String {
    func filenameComponents() -> (name:String,ext:String) {
        if let range = self.range(of: ".", options: .backwards, range: nil, locale: nil) {
            let nameRange = self.startIndex ..< range.upperBound
            let extRange = range.lowerBound ..< self.endIndex
            var name = self
            var ext = self
            name.removeSubrange(extRange)
            ext.removeSubrange(nameRange)
            return (name:name, ext:ext)
        } else {
            return (name:self, ext:String())
        }
    }

    func substr(offset: Int, count: Int) -> String? {
        guard offset < self.count
            else { return nil }
        guard count > 0
            else { return String() }
        guard (count + offset) <= self.count
            else { return nil }
        let start   = index(startIndex, offsetBy: offset)
        let end     = index(start, offsetBy: count)
        return String(describing: self[start..<end])
    }
    
    subscript(offset: Int) -> Character? {
        guard offset < self.count
            else { return nil }
        return self[index(startIndex, offsetBy: offset)]
    }

    func lastOf(ch: Character) -> Int? {
        guard let start = self.reversed().firstIndex(of: ch) else {
            return nil
        }
        return distance(from: startIndex, to: start.base) - 1
    }
    
    var isAsicContainerExtension: Bool {
        let ext = self.lowercased()
        return
            ext == ContainerFormatAdoc    ||
            ext == ContainerFormatBdoc    ||
            ext == ContainerFormatDdoc    ||
            ext == ContainerFormatEdoc    ||
            ext == ContainerFormatAsice   ||
            ext == ContainerFormatAsics   ||
            ext == ContainerFormatAsiceShort    ||
            ext == ContainerFormatAsicsShort
    }
    
    var isPdfContainerExtension: Bool {
        return self.lowercased() == ContainerFormatPDF
    }
    
    var isCdocContainerExtension: Bool {
        return self.lowercased() == ContainerFormatCdoc
    }
    
    var isXmlFileExtension: Bool {
        return self.lowercased() == FileFormatXml
    }
    
    var isNumeric: Bool {
        let prevCount = count
        let digits = components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
        return prevCount == digits.count
    }
    
    static var zeroWidthSpace: String {
        return "\u{200b}"
    }
    
    func substr(toLast character: Character) -> String? {
        guard let lastCharIndex = self.lastOf(ch: character) else {
            return nil
        }
        guard let substrTo = self.substr(offset: 0, count: lastCharIndex + 1) else {
            return nil
        }
        return substrTo
    }
    
    func substr(fromLast character: Character) -> String? {
        guard let lastCharIndex = self.lastOf(ch: character) else {
            return nil
        }
        guard let substrFrom = self.substr(offset: lastCharIndex + 1, count: count - lastCharIndex - 1) else {
            return nil
        }
        return substrFrom
    }
    
    var containsSameDigits: Bool {
        var prevDigit:Int? = nil
        for ch in self {
            if let digit = Int(String(ch)) {
                if let prevDigit = prevDigit {
                    if digit != prevDigit {
                        return false
                    }
                }
                prevDigit = digit
            }
        }
        return true
    }
    
    var isDigitsGrowingOrShrinking: Bool {
        var prevDigit:Int? = nil
        var delta:Int = 0
        var prevDelta:Int? = nil
        for ch in self {
            if let digit = Int(String(ch)) {
                if let prevDigit = prevDigit {
                    delta = digit - prevDigit
                    if abs(delta) != 1 {
                        return false
                    }
                    if let prevDelta = prevDelta, prevDelta != delta {
                        return false
                    }
                    prevDelta = delta
                }
                prevDigit = digit
            }
        }
        return true
    }
    
    func getFirstLinkInMessage() -> String? {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let urls = detector.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
            
            return urls.first?.url?.absoluteString
        } catch {
            printLog("Unable to get URL from text")
            return nil
        }
    }
    
    func removeFirstLinkFromMessage() -> String? {
        guard let messageWithLink = self.getFirstLinkInMessage() else { return self }
        return self.replacingOccurrences(of: messageWithLink, with: "")
    }
    
    var isValidUrl: Bool {
        if let url: URL = URL(string: self) {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
    
    var asUnicode: String {
        let textAsData = self.data(using: .nonLossyASCII)
        let textAsUnicode = String(data: textAsData ?? Data(), encoding: .utf8) ?? ""
        return #"\#(textAsUnicode)"#
    }
}

extension Optional where Wrapped == String {
    var isNilOrEmpty:Bool {
        if let value = self, !value.isEmpty {
            return false
        }
        return true
    }
}

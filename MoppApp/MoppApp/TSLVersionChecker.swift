//
//  TSLVersionChecker.swift
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

class TSLVersionChecker: NSObject, XMLParserDelegate {

    private var fileTSLVersion: String = ""
    private var tslVersionFound: Bool = false

    private var isTSLVersionSet = false
    private var tslVersion: String = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "TSLSequenceNumber" || elementName == "tsl:TSLSequenceNumber" {
            tslVersionFound = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters foundValue: String) {
        if tslVersionFound == true {
            fileTSLVersion = foundValue
        }

        if tslVersionFound == true && fileTSLVersion == foundValue {
            if isTSLVersionSet == false {
                isTSLVersionSet = true

                tslVersion = fileTSLVersion
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        tslVersionFound = false
    }

    internal func getTSLVersion(filePath: URL, completionHandler: @escaping (_ url: String) -> Void) {
        do {
            let fileData: Data = try Data(contentsOf: filePath)
            let xmlParser = XMLParser(data: fileData)
            xmlParser.delegate = self
            if xmlParser.parse() {
                completionHandler(tslVersion)
            }
        } catch {
            printLog("Error converting file (\(filePath)) to Data object")
        }
    }
}

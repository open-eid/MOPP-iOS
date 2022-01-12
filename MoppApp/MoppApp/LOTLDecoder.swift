//
//  LOTLDecoder.swift
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
import UIKit

class LOTLDecoder: NSObject, XMLParserDelegate {
    
    private var currentElementName: String = ""
    private var currentElementValue: String = ""
    private var currentElementMimetype: String = ""
    private var schemeTerritoryFound: Bool = false
    private var tslLocationFound: Bool = false
    private var mimeTypeFound: Bool = false
    
    private let xmlMimeType = "application/vnd.etsi.tsl+xml"
    
    private var country = ""
    private var tslUrlFound = false
    
    var countryTSL: [String: String] = [:]
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "SchemeTerritory" {
            schemeTerritoryFound = true
        } else if elementName == "TSLLocation" {
            tslLocationFound = true
        } else if elementName.contains("MimeType") {
            mimeTypeFound = true
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters foundValue: String) {
        if schemeTerritoryFound == true {
            currentElementName = foundValue
        } else if tslLocationFound == true {
            currentElementValue = foundValue
        } else if mimeTypeFound == true {
            currentElementMimetype = foundValue
        }
        
        if currentElementName == country && currentElementValue.hasSuffix(xmlMimeType.suffix(3)) && currentElementMimetype == xmlMimeType {
            if tslUrlFound == false {
                tslUrlFound = true
                
                countryTSL[country] = currentElementValue
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        schemeTerritoryFound = false
        tslLocationFound = false
        mimeTypeFound = false
    }
    
    
    internal func getUrl(LOTLUrl: String, country: String, completionHandler: @escaping (_ url: String) -> Void) {
        let url = URL(string: LOTLUrl)!
        let xmlParser = XMLParser(contentsOf: url)
        self.country = country
        xmlParser!.delegate = self
        if xmlParser!.parse() {
            completionHandler(countryTSL[country] ?? "")
        }
    }
}

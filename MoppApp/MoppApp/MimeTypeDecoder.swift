//
//  MimeTypeDecoder.swift
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

import Foundation
import UIKit

class MimeTypeDecoder: NSObject, XMLParserDelegate {
    
    private var currentElementName: String = ""
    private var currentElementValue: String = ""
    
    private var ddocFound: Bool = false
    private var cdocFound: Bool = false
    
    private var extensionName: String = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "SignedDoc" && attributeDict["format"] == "DIGIDOC-XML" {
            ddocFound = true
        }
        
        if elementName == "denc:EncryptionProperty" && attributeDict["Name"] == "DocumentFormat" {
            cdocFound = true
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters foundValue: String) {
        if ddocFound == true {
            currentElementName = foundValue
        } else if cdocFound == true {
            currentElementName = foundValue
        }
        
        if currentElementName == foundValue && ddocFound == true {
            extensionName = "ddoc"
        } else if currentElementName == foundValue && cdocFound == true {
            extensionName = "cdoc"
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        ddocFound = false
        cdocFound = false
    }
    
    
    internal func getMimeType(fileString: String, completionHandler: @escaping (_ url: String) -> Void) {
        let fileData: Data? = fileString.data(using: .utf8)
        let xmlParser = XMLParser(data: fileData ?? Data())
        xmlParser.delegate = self
        if xmlParser.parse() {
            completionHandler(extensionName)
        }
    }
}

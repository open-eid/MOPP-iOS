//
//  SivaUtil.swift
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
import PDFKit
import MoppLib

class SiVaUtil {
    static func isDocumentSentToSiVa(fileUrl: URL?) -> Bool {
        guard let fileLocation = fileUrl else { return false }
        let containerTypes = ["asics", "scs", "ddoc"]
        let containerType = MimeTypeExtractor.determineContainer(mimetype: MimeTypeExtractor.getMimeTypeFromContainer(filePath: fileLocation), fileExtension: fileLocation.pathExtension).lowercased()
        
        if containerType == "pdf" {
            let isSignedPDF = isSignedPDF(url: fileLocation as CFURL)
            return isSignedPDF
        }
        
        let isCades = MimeTypeExtractor.isCadesContainer(filePath: fileLocation)
        let isSentToSiva = containerTypes.contains(containerType) || isCades
        
        return isSentToSiva
    }
    
    static func displaySendingToSiVaDialog(completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: L(.sivaSendMessage).removeFirstLinkFromMessage(), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L(.actionYes).uppercased(), style: .default, handler: { (_ action: UIAlertAction) in
            setIsSentToSiva(isSent: true)
            completionHandler(true)
        }))
        alert.addAction(UIAlertAction(title: L(.actionAbort), style: .default, handler: {(_ action: UIAlertAction) -> Void in
            setIsSentToSiva(isSent: false)
            completionHandler(false)
        }))
        if let linkInUrl: String = L(.sivaSendMessage).getFirstLinkInMessage() {
            if let alertActionUrl: UIAlertAction = UIAlertAction().getLinkAlert(message: linkInUrl), !alertActionUrl.title.isNilOrEmpty {
                alert.addAction(alertActionUrl)
            }
        }
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
    }
    
    static func isSignedPDF(url: CFURL) -> Bool {
        
        let pdfPage: CGPDFPage? = CGPDFDocument(url)?.page(at: 1)
        
        guard let page = pdfPage else { return false }
        
        let pageDictionary: CGPDFDictionaryRef? = page.dictionary
        
        guard let dictionary = pageDictionary else { return false }
        
        var pdfArray: CGPDFArrayRef? = nil
        let hasAnnotations = CGPDFDictionaryGetArray(dictionary, "Annots", &pdfArray)
        
        if hasAnnotations {
            
            guard let pdfAnnots: CGPDFArrayRef = pdfArray else { return false }
            
            let annotationsCount = CGPDFArrayGetCount(pdfAnnots)
            
            var pdfDictionary: CGPDFDictionaryRef?
            for (index, _) in [annotationsCount].enumerated() {
                
                let hasDictionary = CGPDFArrayGetDictionary(pdfAnnots, index, &pdfDictionary)
                
                guard let annotDictionary: CGPDFArrayRef = pdfDictionary else { return false }
                
                if hasDictionary {
                    var type: UnsafePointer<CChar>?
                    let hasType = CGPDFDictionaryGetName(annotDictionary, "Type", &type)
                    
                    if hasType && strcmp(type, "Annot") == 0 {
                        var vArray: CGPDFDictionaryRef?
                        CGPDFDictionaryGetDictionary(annotDictionary, "V", &vArray);
                        
                        guard let vInfo: CGPDFArrayRef = vArray else { return false }
                        
                        var filterChar: UnsafePointer<CChar>?
                        CGPDFDictionaryGetName(vInfo, "Filter", &filterChar)
                        
                        var subFilterChar: UnsafePointer<CChar>?
                        CGPDFDictionaryGetName(vInfo, "SubFilter", &subFilterChar)
                        
                        var filter = ""
                        if let filterName = filterChar {
                            filter = String(cString: filterName)
                        }
                        
                        var subFilter = ""
                        if let subFilterName = subFilterChar {
                            subFilter = String(cString: subFilterName)
                        }
                        
                        return filter == "Adobe.PPKLite" || (subFilter == "ETSI.CAdES.detached" || subFilter == "adbe.pkcs7.detached")
                    }
                }
            }
        }
        
        return false
    }
    
    static func setIsSentToSiva(isSent: Bool) {
        let validateOnlineInstance = MoppLibDigidocValidateOnline.sharedInstance()
        validateOnlineInstance?.validateOnline = isSent
    }
}

//
//  SivaUtil.swift
//  MoppApp
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
import PDFKit

class SiVaUtil {
    static func isDocumentSentToSiVa(fileUrl: URL?) -> Bool {
        guard let fileLocation = fileUrl else { return false }
        let containerType = MimeTypeExtractor.determineContainer(mimetype: MimeTypeExtractor.getMimeTypeFromContainer(filePath: fileLocation), fileExtension: fileLocation.pathExtension)
        
        var isDSSPDFDocument = false
        
        if containerType == "pdf" {
            let pdfDoc = PDFDocument(url: fileLocation) ?? PDFDocument()
            guard let pdfDocCatalog = pdfDoc.documentRef?.catalog else { return false }
            CGPDFDictionaryApplyBlock(pdfDocCatalog, { key, object, _ in
                let catalogKey = String(cString: key, encoding: .utf8)
                if catalogKey != nil && catalogKey == "DSS" {
                    isDSSPDFDocument = true
                }
                return true
            }, nil)
        }
        
        return isDSSPDFDocument || containerType == "ddoc" || containerType == "asics" || containerType == "scs"
    }
    
    static func displaySendingToSiVaDialog(completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: L(.sivaSendMessage).removeFirstLinkFromMessage(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L(.actionYes).uppercased(), style: .default, handler: { (_ action: UIAlertAction) in
            completionHandler(true)
        }))
        alert.addAction(UIAlertAction(title: L(.actionAbort), style: .default, handler: {(_ action: UIAlertAction) -> Void in
            completionHandler(false)
        }))
        if let linkInUrl: String = L(.sivaSendMessage).getFirstLinkInMessage() {
            if let alertActionUrl: UIAlertAction = UIAlertAction().getLinkAlert(message: linkInUrl) {
                alert.addAction(alertActionUrl)
            }
        }
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
    }
}

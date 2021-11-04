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
import ILPDFKit

class SiVaUtil {
    static func isDocumentSentToSiVa(fileUrl: URL?) -> Bool {
        guard let fileLocation = fileUrl else { return false }
        let containerType = MimeTypeExtractor.determineContainer(mimetype: MimeTypeExtractor.getMimeTypeFromContainer(filePath: fileLocation), fileExtension: fileLocation.pathExtension)
        
        if containerType == "pdf" {
            let document = ILPDFDocument(path: fileLocation.path)
            let forms = document.forms as ILPDFFormContainer
            
            let pdfSignatures = forms.forms(with: .signature)
            if !pdfSignatures.isEmpty {
                for pdfSignature in pdfSignatures {
                    if let signatureDictionary: ILPDFDictionary = pdfSignature.dictionary,
                       let vKey: ILPDFDictionary = signatureDictionary["V" as NSString] as? ILPDFDictionary,
                       let filter = vKey["Filter" as NSString] as? NSString,
                       let subFilter = vKey["SubFilter" as NSString] as? NSString {
                        return filter == "Adobe.PPKLite" || (subFilter == "ETSI.CAdES.detached" || subFilter == "adbe.pkcs7.detached")
                    }
                }
            }
        }
        
        return containerType == "ddoc" || containerType == "asics" || containerType == "scs"
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

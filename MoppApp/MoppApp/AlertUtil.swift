//
//  AlertUtil.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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
import SkSigningLib

class AlertUtil {
    
    static func messageAlert(title: String? = nil, message: String?, okButtonTitle: String? = "OK", additionalInfoButtonTitle: String? = nil, alertAction: ((UIAlertAction) -> Void)?) -> UIAlertController {
        let alertTitle = L(.emptySpace)
        let okButton = okButtonTitle ?? L(.actionOk)
        let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButton, style: .default, handler: alertAction))
        
        return alert
    }
    
    static func messageAlertWithLink(title: String? = nil, message: String?, okButtonTitle: String? = "OK", additionalInfoButtonTitle: String? = nil, alertAction: ((UIAlertAction) -> Void)?) -> UIAlertController {
        var messageNoLink: String? = message
        if let messageText = message {
            messageNoLink = messageText.removeFirstLinkFromMessage()
        }
        let alertTitle = L(.emptySpace)
        let okButton = okButtonTitle ?? L(.actionOk)
        let alert = UIAlertController(title: alertTitle, message: messageNoLink, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButton, style: .default, handler: alertAction))
        if let linkInUrl: String = message?.getFirstLinkInMessage() {
            if let alertActionUrl: UIAlertAction = UIAlertAction().getLinkAlert(title: additionalInfoButtonTitle, message: linkInUrl), !alertActionUrl.title.isNilOrEmpty {
                alert.addAction(alertActionUrl)
            }
        }
        
        return alert
    }
    
    static func errorMessageDialog(_ notification: Notification, topViewController: UIViewController) {
        guard let userInfo = notification.userInfo else { return }
        let error = userInfo[kErrorKey] as? NSError
        let signingErrorMessage = (error as? SigningError)?.signingErrorDescription
        let signingError = error?.userInfo[NSLocalizedDescriptionKey] as? SigningError
        // Don't show an error when request is cancelled
        if let err = error, ((err as? SigningError) == SigningError.cancelled) || signingError == .cancelled {
            topViewController.dismiss(animated: true)
            return
        }
        let signingStringError = error?.userInfo[NSLocalizedDescriptionKey] as? String
        let detailedErrorMessage = error?.userInfo[NSLocalizedFailureReasonErrorKey] as? String
        var errorMessage = userInfo[kErrorMessage] as? String ?? SkSigningLib_LocalizedString(signingError?.signingErrorDescription ?? signingErrorMessage ?? signingStringError ?? "")
        if !detailedErrorMessage.isNilOrEmpty {
            errorMessage = "\(userInfo[kErrorMessage] as? String ?? SkSigningLib_LocalizedString(signingError?.signingErrorDescription ?? signingErrorMessage ?? "")) \n\(detailedErrorMessage ?? "")"
        }
        
        let errorDialog = errorDialog(errorMessage: errorMessage, topViewController: topViewController)
        
        if !(topViewController is UIAlertController) {
            topViewController.present(errorDialog, animated: true, completion: nil)
        }
    }

    static func errorDialog(title: String? = nil, errorMessage: String, topViewController: UIViewController) -> UIAlertController {
        let errorMessageNoLink = errorMessage.removeFirstLinkFromMessage()?.trimWhitespacesAndNewlines()
        let alertTitle = L(.emptySpace)
        let alert = UIAlertController(title: alertTitle, message: errorMessageNoLink, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        if let linkInUrl = errorMessage.getFirstLinkInMessage() {
            if let alertActionUrl = UIAlertAction().getLinkAlert(message: linkInUrl), !alertActionUrl.title.isNilOrEmpty {
                alert.addAction(alertActionUrl)
            }
        }
        
        return alert
    }
}

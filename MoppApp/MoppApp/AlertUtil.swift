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

class AlertUtil {
    
    static func messageAlertWithLink(title: String? = nil, message: String?, okButtonTitle: String? = "OK", additionalInfoButtonTitle: String? = nil, alertAction: ((UIAlertAction) -> Void)?) -> UIAlertController {
        var messageNoLink: String? = message
        if let messageText = message {
            messageNoLink = messageText.removeFirstLinkFromMessage()
        }
        let alert = UIAlertController(title: title, message: messageNoLink, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButtonTitle, style: .default, handler: alertAction))
        if let linkInUrl: String = message?.getFirstLinkInMessage() {
            if let alertActionUrl: UIAlertAction = UIAlertAction().getLinkAlert(title: additionalInfoButtonTitle, message: linkInUrl) {
                alert.addAction(alertActionUrl)
            }
        }
        
        return alert
    }
}

//
//  UIAlertAction+Additions.swift
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

extension UIAlertAction {
    func getLinkAlert(message: String?) -> UIAlertAction? {
        if let linkInMessage = message?.getFirstLinkInMessage() {
            let openLinkAction: UIAlertAction = UIAlertAction(title: L(.errorAlertOpenLink), style: .default, handler: { (action) in
                if let messageUrl = URL(string: linkInMessage) {
                    UIApplication.shared.open(messageUrl, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                    NSLog("Opening link: \(messageUrl.absoluteString)")
                }
            })
            
            if let _ = URL(string: linkInMessage) {
                return openLinkAction
            }
        }
        
        return nil
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

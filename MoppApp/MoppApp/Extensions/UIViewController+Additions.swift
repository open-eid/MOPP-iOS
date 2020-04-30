//
//  UIViewController+Additions.swift
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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

extension UIViewController {
    func confirmDeleteAlert(message: String?, confirmCallback: @escaping (_ action: UIAlertAction) -> Void) {
        let confirmDialog = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            confirmDialog.addAction(UIAlertAction(title: L(.actionCancel), style: .default, handler: nil))
            confirmDialog.addAction(UIAlertAction(title: L(.actionDelete), style: .destructive, handler: confirmCallback))
        present(confirmDialog, animated: true, completion: nil)
    }
    
    func errorAlert(message: String?, title: String? = nil, dismissCallback: ((_ action: UIAlertAction) -> Swift.Void)? = nil) {
        var errorMessageNoLink: String? = message
        if let messageText = message {
            errorMessageNoLink = messageText.removeFirstLinkFromMessage()
        }
        let errorAlert = UIAlertController(title: title, message: errorMessageNoLink, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: dismissCallback))
        if let linkInUrl: String = message?.getFirstLinkInMessage() {
            if let alertActionUrl: UIAlertAction = UIAlertAction().getLinkAlert(message: linkInUrl) {
                errorAlert.addAction(alertActionUrl)
            }
        }
        present(errorAlert, animated: true, completion: nil)
    }
    
    func dismissRecursively(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissRecursively(animated: flag, forceCompletion: true, completion: completion)
    }
    
    func dismissRecursivelyIfPresented(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissRecursively(animated: flag, forceCompletion: false, completion: completion)
    }
    
    private func dismissRecursively(animated flag: Bool, forceCompletion:Bool, completion: (() -> Void)? = nil) {
        if let presentedVC = presentedViewController {
            presentedVC.dismissRecursively(animated: flag) { [weak self] in
                self?.dismiss(animated: flag, completion: completion)
            }
        } else {
            if !forceCompletion && presentingViewController == nil {
                return
            } else {
                if presentingViewController == nil {
                    completion?()
                } else {
                    dismiss(animated: flag, completion: completion)
                }
            }
        }
    }
}

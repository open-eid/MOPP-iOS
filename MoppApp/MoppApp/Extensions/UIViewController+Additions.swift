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
        let errorAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: dismissCallback))
        present(errorAlert, animated: true, completion: nil)
    }
}

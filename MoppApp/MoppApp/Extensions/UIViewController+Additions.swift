//
//  UIViewController+Additions.swift
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

extension UIViewController {
    func confirmDeleteAlert(message: String?, confirmCallback: @escaping (_ action: UIAlertAction.DeleteAction) -> Void) {
        let confirmDialog = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        confirmDialog.addAction(UIAlertAction(title: L(.actionCancel), style: .cancel, handler: { _ in
            confirmCallback(.cancel)
        }))
        confirmDialog.addAction(UIAlertAction(title: L(.actionDelete), style: .destructive, handler: { _ in
            confirmCallback(.confirm)
        }))
        present(confirmDialog, animated: true, completion: nil)
    }
    
    func infoAlert(message: String?, dismissCallback: ((_ action: UIAlertAction) -> Swift.Void)? = nil) {
        let messageAlert = AlertUtil.messageAlert(message: message, alertAction: dismissCallback)
        
        present(messageAlert, animated: true, completion: nil)
    }
    
    func errorAlertWithLink(message: String?, dismissCallback: ((_ action: UIAlertAction) -> Swift.Void)? = nil) {
        let errorAlert = AlertUtil.messageAlertWithLink(message: message, alertAction: dismissCallback)
        
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
                completion?()
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
    
    func getTopViewController() -> UIViewController {
        if var topViewController = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            while let currentViewController = topViewController.presentedViewController {
                topViewController = currentViewController
            }
            
            return topViewController
        }
        
        return UIViewController()
    }
    
    func displayMessageDialog(message: String) {
        let uiAlertController: UIAlertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        
        uiAlertController.addAction(UIAlertAction(title: L(.actionOk), style: .default))
        
        self.present(uiAlertController, animated: true, completion: nil)
    }
    
    func showErrorMessage(message: String) {
        DispatchQueue.main.async {
            let topViewController: UIViewController = self.getTopViewController()
            guard topViewController.isViewLoaded else {
                return
            }
            topViewController.infoAlert(message: message, dismissCallback: nil)
        }
    }
}

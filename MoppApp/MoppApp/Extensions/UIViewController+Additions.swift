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
import WebKit

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
    
    static func getInvisibleLabel() -> UILabel {
        let label = UILabel()
        label.text = "Invisible label"
        label.textAlignment = .center
        label.backgroundColor = .lightGray
        label.tag = invisibleElementTag
        label.accessibilityIdentifier = invisibleElementAccessibilityIdentifier
        return label
    }
    
    // Adds an invisible label element to the bottom of the view.
    // Used for autotests by testers
    func addInvisibleBottomLabelTo(_ customView: UIView?) {
        let label = UIViewController.getInvisibleLabel()
        label.text = "Invisible label"
        label.textAlignment = .center
        label.backgroundColor = .lightGray
        label.tag = invisibleElementTag
        label.accessibilityIdentifier = invisibleElementAccessibilityIdentifier

        if DefaultsHelper.isDebugMode {
            label.isHidden = false
            label.isAccessibilityElement = false
            label.alpha = 0.001
            label.isUserInteractionEnabled = true
            label.isEnabled = true
        } else {
            label.isHidden = true
            label.isAccessibilityElement = false
            label.alpha = 0.0
            label.isUserInteractionEnabled = false
            label.isEnabled = false
            return
        }
        
        let usedView = customView ?? view
        
        guard let mainView = usedView else { return }
        
        for subview in mainView.subviews {
            if let scrollView = subview as? UIScrollView,
               let lastSubview = scrollView.subviews.last(where: { type(of: $0) == UIView.self }) {
                addLabelToBottom(label: label, lastSubview: lastSubview)
                changeInvisibleLabelVisibility(label, scrollView, false)
                return
            } else if let lastSubview = view.subviews.last(where: { type(of: $0) == UIView.self }) {
                addLabelToBottom(label: label, lastSubview: lastSubview)
                return
            } else if let _ = view.subviews.last(where: { type(of: $0) == UITableView.self || type(of: $0) == WKWebView.self }) {
                addLabelToBottom(label: label, lastSubview: view)
                return
            } else if let cView = customView {
                addLabelToBottom(label: label, lastSubview: cView)
                return
            }
        }
    }
    
    func addLabelToBottom(label: UILabel?, lastSubview: UIView?) {
        if DefaultsHelper.isDebugMode {
            let lastElement = lastSubview?.subviews.last ?? lastSubview ?? UIView()
            
            if !(lastSubview is UITableView), let viewLabel = label, let viewLastSubview = lastSubview {
                viewLastSubview.insertSubview(viewLabel, aboveSubview: lastElement)
                
                let height = lastElement.frame.height != 0 ? lastElement.frame.height : viewLastSubview.frame.height
                let width = lastElement.frame.width != 0 ? lastElement.frame.width : viewLastSubview.frame.width
                
                viewLabel.translatesAutoresizingMaskIntoConstraints = false
                viewLabel.widthAnchor.constraint(equalToConstant: width).isActive = true
                viewLabel.heightAnchor.constraint(equalToConstant: height).isActive = true
                viewLabel.topAnchor.constraint(equalTo: lastElement.bottomAnchor, constant: 16).isActive = true
                viewLabel.centerXAnchor.constraint(equalTo: lastElement.centerXAnchor).isActive = true
            }
        }
    }
    
    func changeInvisibleLabelVisibility(_ invisibleLabel: UILabel, _ scrollView: UIScrollView?, _ isVisible: Bool? = nil) {
        if let isVisible = isVisible {
            invisibleLabel.isHidden = !isVisible
        } else {
            guard let scrollView = scrollView else {
                invisibleLabel.isHidden = false
                return
            }
            
            let visibleRect = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
            invisibleLabel.isHidden = !visibleRect.intersects(invisibleLabel.frame)
        }
    }
    
    func getInvisibleLabelInView(_ view: UIView?, accessibilityIdentifier identifier: String) -> UILabel? {
        guard let view = view else {
            return nil
        }
        
        if let invisibleLabel = view.subviews.compactMap({ $0 as? UILabel }).first(where: { $0.accessibilityIdentifier == identifier }) {
            return invisibleLabel
        }
        
        for subview in view.subviews {
            if let invisibleLabel = getInvisibleLabelInView(subview, accessibilityIdentifier: identifier) {
                return invisibleLabel
            }
        }
        
        return nil
    }
}

//
//  MyeIDChangeCodeViewControllerUI.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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
@objc
protocol MyeIDChangeCodesViewControllerUIDelegate: AnyObject {
    func didTapDiscardButton(_ ui: MyeIDChangeCodesViewControllerUI)
    func didTapConfirmButton(_ ui: MyeIDChangeCodesViewControllerUI)
}

class MyeIDChangeCodesViewControllerUI: NSObject {
    @IBOutlet weak var delegate: MyeIDChangeCodesViewControllerUIDelegate!
    private weak var viewController: MyeIDChangeCodesViewController!
    private var isKeyboardVisible = false
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewContentView: UIView!
    @IBOutlet weak var firstInfoLabel: UILabel!
    @IBOutlet weak var secondInfoLabel: UILabel!
    @IBOutlet weak var thirdInfoLabel: UILabel!
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var firstCodeTextField: UITextField!
    @IBOutlet weak var secondCodeTextField: UITextField!
    @IBOutlet weak var thirdCodeTextField: UITextField!
    @IBOutlet weak var firstCodeTextFieldLabel: UILabel!
    @IBOutlet weak var secondCodeTextFieldLabel: UILabel!
    @IBOutlet weak var thirdCodeTextFieldLabel: UILabel!
    @IBOutlet weak var firstInlineErrorLabel: UILabel!
    @IBOutlet weak var secondInlineErrorLabel: UILabel!
    @IBOutlet weak var statusViewVisibleCSTR: NSLayoutConstraint!
    @IBOutlet weak var statusViewHiddenCSTR: NSLayoutConstraint!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBAction func discardButtonTapped() {
        delegate.didTapDiscardButton(self)
    }
    
    @IBAction func confirmButtonTapped() {
        delegate.didTapConfirmButton(self)
    }
    
    func setupWithModel(_ model: MyeIDChangeCodesModel, _ controller: MyeIDChangeCodesViewController) {
        viewController = controller
        controller.setupNavigationItemForPushedViewController(title: model.titleText)
        firstCodeTextFieldLabel.text = model.firstTextFieldLabelText
        secondCodeTextFieldLabel.text = model.secondTextFieldLabelText
        thirdCodeTextFieldLabel.text = model.thirdTextFieldLabelText
        discardButton.setTitle(model.discardButtonTitleText)
        confirmButton.setTitle(model.confirmButtonTitleText)
        
        discardButton.accessibilityLabel = setDiscardButtonAccessibilityLabel(actionType: model.actionType)
        confirmButton.accessibilityLabel = setConfirmButtonAccessibilityLabel(actionType: model.actionType)
        
        firstCodeTextField.delegate = self
        secondCodeTextField.delegate = self
        thirdCodeTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        let font = UIFont.setCustomFont(font: .regular, nil, .body)
        let color = UIColor.moppText
        let attributes = [NSAttributedString.Key.font : font, NSAttributedString.Key.foregroundColor : color]
        
        firstCodeTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        secondCodeTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        thirdCodeTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        
        var partAttributedStrings = [String]()
        var fullAttributedStrings = [NSMutableAttributedString]()
        
        let textAttachment = NSTextAttachment()
        textAttachment.image = UIImage(named: "bullet")!.withRenderingMode(.alwaysTemplate)
        textAttachment.image?.isAccessibilityElement = false
        textAttachment.image?.accessibilityLabel = ""
        textAttachment.accessibilityTraits = [.none]
        textAttachment.image?.accessibilityTraits = [.none]
        
        textAttachment.isAccessibilityElement = false
        
        for index in 0..<model.infoBullets.count {
            let infoBullet = model.infoBullets[index]
            let attributedString: NSMutableAttributedString = NSMutableAttributedString(
                    string: String(), attributes: attributes)
                attributedString.append(NSAttributedString(string: String.zeroWidthSpace, attributes: attributes))
                attributedString.append(NSAttributedString(attachment: textAttachment))
                attributedString.append(NSAttributedString(string: "\t\(infoBullet)", attributes: attributes))
            if index < (model.infoBullets.count - 1) {
                attributedString.append(NSAttributedString(string: "\n", attributes: attributes))
            }
            
            let paragraphStyle = createParagraphAttribute()
            attributedString.addAttributes(
                attributes.merging([NSAttributedString.Key.paragraphStyle: paragraphStyle],
                    uniquingKeysWith: {current,_  in return current }),
                range: NSMakeRange(0, attributedString.length))
            
            fullAttributedStrings.append(attributedString)
            partAttributedStrings.append(infoBullet)
        }
        
        firstInfoLabel.isAccessibilityElement = true
        secondInfoLabel.isAccessibilityElement = true
        thirdInfoLabel.isAccessibilityElement = true
        
        firstInfoLabel.attributedText = fullAttributedStrings.indices.contains(0) ? fullAttributedStrings[0] : NSAttributedString()
        secondInfoLabel.attributedText = fullAttributedStrings.indices.contains(1) ? fullAttributedStrings[1] : NSAttributedString()
        thirdInfoLabel.attributedText = fullAttributedStrings.indices.contains(2) ? fullAttributedStrings[2] : NSAttributedString()
    
        firstInfoLabel.accessibilityLabel = partAttributedStrings.indices.contains(0) ? partAttributedStrings[0] : ""
        secondInfoLabel.accessibilityLabel = partAttributedStrings.indices.contains(1) ? partAttributedStrings[1] : ""
        thirdInfoLabel.accessibilityLabel = partAttributedStrings.indices.contains(2) ? partAttributedStrings[2] : ""
        
        statusViewHiddenCSTR.priority = UILayoutPriority.defaultHigh
        statusViewVisibleCSTR.priority = UILayoutPriority.defaultLow
        
        if isNonDefaultPreferredContentSizeCategory() || isBoldTextEnabled() {
            setCustomFont()
        }
    }
    
    func createParagraphAttribute() -> NSParagraphStyle
    {
        var paragraphStyle: NSMutableParagraphStyle
        paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 30, options: [:])]
        paragraphStyle.defaultTabInterval = 30
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 30
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.firstLineHeadIndent = 0
        
        return paragraphStyle
    }
    
    @objc func adjustForKeyboard(notification: NSNotification) {
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = UIEdgeInsets.zero
            isKeyboardVisible = false
        
        } else if notification.name == UIResponder.keyboardWillShowNotification {
            if isKeyboardVisible { return }
            
            let userInfo = notification.userInfo!
            
            let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let keyboardViewEndFrame = viewController.view.convert(keyboardScreenEndFrame, from: viewController.view.window)
            
            let scrollViewRectInWindow = scrollView.convert(scrollView.frame, from: viewController.view.window)
            let bottomMargin = (viewController.view.window?.frame.height ?? 0) - (scrollViewRectInWindow.height - scrollViewRectInWindow.origin.y)
            
            var bottomContentInset = keyboardViewEndFrame.height - bottomMargin + 8
            
            let scrollViewContentDelta = scrollView.contentSize.height - scrollView.frame.height
            if scrollViewContentDelta > 0 {
                bottomContentInset += scrollViewContentDelta
            }
        
            scrollView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: bottomContentInset, right: 0)
            isKeyboardVisible = true
        }
    }
    
    func showStatusView(with title: String) {
        statusLabel.text = title
        self.scrollView.contentOffset = CGPoint.zero
        UIView.animate(withDuration: 0.35, delay: 0.0, options: UIView.AnimationOptions.curveLinear, animations: { [weak self] in
            self?.statusViewHiddenCSTR.priority = UILayoutPriority.defaultLow
            self?.statusViewVisibleCSTR.priority = UILayoutPriority.defaultHigh
            self?.viewController.view.layoutIfNeeded()
        }) { (finished) in
            UIView.animate(withDuration: 0.35, delay: 3.0, options: UIView.AnimationOptions.curveLinear, animations: { [weak self] in
                self?.statusViewHiddenCSTR.priority = UILayoutPriority.defaultHigh
                self?.statusViewVisibleCSTR.priority = UILayoutPriority.defaultLow
                self?.viewController.view.layoutIfNeeded()
            }) { (finished) in }
        }
    }
    
    func setDiscardButtonAccessibilityLabel(actionType: MyeIDChangeCodesModel.ActionType) -> String {
        switch actionType {
        case .changePin1:
            return L(.myEidDiscardPin1ButtonTitleAccessibility)
        case .changePin2:
            return L(.myEidDiscardPin2ButtonTitleAccessibility)
        case .changePuk:
            return L(.myEidDiscardPukChangeButtonTitleAccessibility)
        case .unblockPin1:
            return L(.myEidDiscardPin1UnblockButtonTitleAccessibility)
        case .unblockPin2:
            return L(.myEidDiscardPin2UnblockButtonTitleAccessibility)
        }
    }
    
    func setConfirmButtonAccessibilityLabel(actionType: MyeIDChangeCodesModel.ActionType) -> String {
        switch actionType {
        case .changePin1:
            return L(.myEidConfirmPin1ChangeButtonTitleAccessibility)
        case .changePin2:
            return L(.myEidConfirmPin2ChangeButtonTitleAccessibility)
        case .changePuk:
            return L(.myEidConfirmPukChangeButtonTitleAccessibility)
        case .unblockPin1:
            return L(.myEidConfirmPin1UnblockButtonTitleAccessibility)
        case .unblockPin2:
            return L(.myEidConfirmPin2UnblockButtonTitleAccessibility)
        }
    }
    
    func clearCodeTextFields() {
        firstCodeTextField.text = nil
        secondCodeTextField.text = nil
        thirdCodeTextField.text = nil
    }
    
    func clearInlineErrors() {
        firstInlineErrorLabel.text = nil
        secondInlineErrorLabel.text = nil
        removeViewBorder(view: firstCodeTextField)
        removeViewBorder(view: secondCodeTextField)
        removeViewBorder(view: thirdCodeTextField)
    }
    
    func setCustomFont() {
        firstInfoLabel.font = UIFont.setCustomFont(font: .medium, nil, .body)
        secondInfoLabel.font = UIFont.setCustomFont(font: .regular, nil, .body)
        thirdInfoLabel.font = UIFont.setCustomFont(font: .regular, nil, .body)
        discardButton.titleLabel?.font = UIFont.setCustomFont(font: .regular, isNonDefaultPreferredContentSizeCategoryBigger() ? 11 : nil, .body)
        confirmButton.titleLabel?.font = UIFont.setCustomFont(font: .regular, isNonDefaultPreferredContentSizeCategoryBigger() ? 11 : nil, .body)
        firstCodeTextFieldLabel.font = UIFont.setCustomFont(font: .allCapsRegular, nil, .body)
        secondCodeTextFieldLabel.font = UIFont.setCustomFont(font: .allCapsRegular, nil, .body)
        thirdCodeTextFieldLabel.font = UIFont.setCustomFont(font: .allCapsRegular, nil, .body)
        firstInlineErrorLabel.font = UIFont.setCustomFont(font: .regular, nil, .body)
        secondInlineErrorLabel.font = UIFont.setCustomFont(font: .regular, nil, .body)
        statusLabel.font = UIFont.setCustomFont(font: .regular, nil, .body)
    }
    
    func setViewBorder(view: UIView) {
        view.layer.borderColor = UIColor.moppError.cgColor
        view.layer.borderWidth = 1.0
    }
    
    func removeViewBorder(view: UIView) {
        view.layer.borderColor = UIColor.moppContentLine.cgColor
        view.layer.borderWidth = 1.0
    }
}

extension MyeIDChangeCodesViewControllerUI: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: textField)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: textField)
    }
}

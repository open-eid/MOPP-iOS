//
//  MyeIDChangeCodeViewControllerUI.swift
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
@objc
protocol MyeIDChangeCodesViewControllerUIDelegate: class {
    func didTapDiscardButton(_ ui: MyeIDChangeCodesViewControllerUI)
    func didTapConfirmButton(_ ui: MyeIDChangeCodesViewControllerUI)
}

class MyeIDChangeCodesViewControllerUI: NSObject {
    @IBOutlet weak var delegate: MyeIDChangeCodesViewControllerUIDelegate!
    private weak var viewController: MyeIDChangeCodesViewController!
    private var isKeyboardVisible = false
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewContentView: UIView!
    @IBOutlet weak var textView: UITextView!
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
    @IBOutlet weak var thirdInlineErrorLabel: UILabel!
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
        
        firstCodeTextField.delegate = self
        secondCodeTextField.delegate = self
        thirdCodeTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        let font = UIFont(name: MoppFontName.regular.rawValue, size: 16)!
        let color = UIColor.moppText
        let attributes = [NSAttributedStringKey.font : font, NSAttributedStringKey.foregroundColor : color]
        
        let fullAttributedString = NSMutableAttributedString()
        
        let textAttachment = NSTextAttachment()
            textAttachment.image = UIImage(named: "bullet")!.withRenderingMode(.alwaysTemplate)
        
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
                attributes.merging([NSAttributedStringKey.paragraphStyle: paragraphStyle],
                    uniquingKeysWith: {current,_  in return current }),
                range: NSMakeRange(0, attributedString.length))
            
            fullAttributedString.append(attributedString)
        }
        
        textView.attributedText = fullAttributedString
        
        statusViewHiddenCSTR.priority = UILayoutPriority.defaultHigh
        statusViewVisibleCSTR.priority = UILayoutPriority.defaultLow
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
        
        if notification.name == NSNotification.Name.UIKeyboardWillHide {
            scrollView.contentInset = UIEdgeInsets.zero
            isKeyboardVisible = false
        
        } else if notification.name == NSNotification.Name.UIKeyboardWillShow {
            if isKeyboardVisible { return }
            
            let userInfo = notification.userInfo!
            
            let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let keyboardViewEndFrame = viewController.view.convert(keyboardScreenEndFrame, from: viewController.view.window)
            
            let scrollViewRectInWindow = scrollView.convert(scrollView.frame, from: viewController.view.window)
            let bottomMargin = (viewController.view.window?.frame.height ?? 0) - (scrollViewRectInWindow.height - scrollViewRectInWindow.origin.y)
            
            var bottomContentInset = keyboardViewEndFrame.height - bottomMargin + 8
            
            let scrollViewContentDelta = scrollView.contentSize.height - scrollView.frame.height
            if scrollViewContentDelta > 0 {
                bottomContentInset += scrollViewContentDelta
            }
        
            scrollView.contentInset = UIEdgeInsetsMake(0, 0, bottomContentInset, 0)
            isKeyboardVisible = true
        }
    }
    
    func showStatusView(with title: String) {
        statusLabel.text = title
        UIView.animate(withDuration: 0.35, delay: 0.0, options: UIViewAnimationOptions.curveLinear, animations: { [weak self] in
            self?.statusViewHiddenCSTR.priority = UILayoutPriority.defaultLow
            self?.statusViewVisibleCSTR.priority = UILayoutPriority.defaultHigh
            self?.viewController.view.layoutIfNeeded()
        }) { (finished) in
            UIView.animate(withDuration: 0.35, delay: 3.0, options: UIViewAnimationOptions.curveLinear, animations: { [weak self] in
                self?.statusViewHiddenCSTR.priority = UILayoutPriority.defaultHigh
                self?.statusViewVisibleCSTR.priority = UILayoutPriority.defaultLow
                self?.viewController.view.layoutIfNeeded()
            }) { (finished) in }
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
        thirdInlineErrorLabel.text = nil
    }
}

extension MyeIDChangeCodesViewControllerUI: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

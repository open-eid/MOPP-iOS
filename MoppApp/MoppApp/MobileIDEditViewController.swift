//
//  MobileIDEditViewController.swift
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
import UIKit


class MyTextField : ScaledTextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds
            rect.origin.x = 10
            rect.size.width -= 20
        return rect
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds
            rect.origin.x = 10
            rect.size.width -= 20
        return rect
    }
}

protocol MobileIDEditViewControllerDelegate : AnyObject {
    func mobileIDEditViewControllerDidDismiss(cancelled: Bool, phoneNumber: String?, idCode: String?)
}

class MobileIDEditViewController : MoppViewController, TokenFlowSigning {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var idCodeTextField: PersonalCodeField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var centerViewCenterCSTR: NSLayoutConstraint!
    @IBOutlet weak var centerViewOutofscreenCSTR: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var idCodeLabel: UILabel!
    @IBOutlet weak var phoneNumberErrorLabel: UILabel!
    @IBOutlet weak var personalCodeErrorLabel: UILabel!
    @IBOutlet weak var cancelButton: MoppButton!
    @IBOutlet weak var signButton: MoppButton!
    @IBOutlet weak var rememberLabel: UILabel!
    @IBOutlet weak var rememberSwitch: UISwitch!
    @IBOutlet weak var rememberStackView: UIStackView!
    @IBOutlet weak var actionButtonsStackView: UIStackView!
    
    weak var delegate: MobileIDEditViewControllerDelegate? = nil
    var tapGR: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()

        idCodeTextField.moppPresentDismissButton()
        phoneTextField.moppPresentDismissButton()

        titleLabel.text = L(.mobileIdTitle)
        phoneLabel.text = L(.mobileIdPhoneTitle)
        idCodeLabel.text = L(.signingIdcodeTitle)
        cancelButton.setTitle(L(.actionCancel).uppercased())
        signButton.setTitle(L(.actionSign).uppercased())
        rememberLabel.text = L(.signingRememberMe)
        
        cancelButton.adjustedFont()
        signButton.adjustedFont()
        
        rememberLabel.isAccessibilityElement = false
        rememberSwitch.accessibilityLabel = L(.signingRememberMe)

        phoneLabel.isAccessibilityElement = false
        idCodeLabel.isAccessibilityElement = false
        rememberLabel.isAccessibilityElement = false
        
        phoneTextField.isAccessibilityElement = true

        phoneTextField.accessibilityLabel = L(.mobileIdPhoneTitle)

        phoneTextField.accessibilityUserInputLabels = [L(.voiceControlPhoneNumber)]
        
        idCodeTextField.accessibilityLabel = L(.signingIdcodeTitle)
        rememberSwitch.accessibilityLabel = rememberLabel.text

        phoneNumberErrorLabel.text = ""
        phoneNumberErrorLabel.isHidden = true
        personalCodeErrorLabel.text = ""
        personalCodeErrorLabel.isHidden = true

        idCodeTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        idCodeTextField.layer.borderWidth = 1.0

        phoneTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        phoneTextField.layer.borderWidth = 1.0
        
        rememberSwitch.addTarget(self, action: #selector(toggleRememberMe), for: .valueChanged)

        self.phoneTextField.delegate = self
        self.idCodeTextField.delegate = self
        
        tapGR = UITapGestureRecognizer()
        tapGR.addTarget(self, action: #selector(cancelAction))
        view.addGestureRecognizer(tapGR)
        
        if UIAccessibility.isVoiceOverRunning {
            guard let titleUILabel = titleLabel, let phoneUILabel = phoneLabel, let phoneUITextField = phoneTextField, let phoneNumberErrorUILabel = phoneNumberErrorLabel, let idCodeUILabel = idCodeLabel, let idCodeUITextField = idCodeTextField, let personalCodeUIErrorLabel = personalCodeErrorLabel, let rememberUILabel = rememberLabel, let rememberUISwitch = rememberSwitch, let cancelUIButton = cancelButton, let signUIButton = signButton else {
                printLog("Unable to get titleLabel, phoneLabel, phoneTextField, phoneNumberErrorLabel, idCodeLabel, idCodeTextField, personalCodeErrorLabel, rememberLabel, rememberSwitch, cancelButton or signButton")
                return
            }
            
            
            self.view.accessibilityElements = [titleUILabel, phoneUILabel, phoneUITextField, phoneNumberErrorUILabel, idCodeUILabel, idCodeUITextField, personalCodeUIErrorLabel, rememberUILabel, rememberUISwitch, cancelUIButton, signUIButton]
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAccessibilityKeyboard), name: .hideKeyboardAccessibility, object: nil)
    }

    @objc func dismissKeyboard(_ notification: NSNotification) {
        idCodeTextField.resignFirstResponder()
        phoneTextField.resignFirstResponder()
    }

    @IBAction func cancelAction() {
        dismiss(animated: false) {
            [weak self] in
            guard let sself = self else { return }
            sself.delegate?.mobileIDEditViewControllerDidDismiss(
                cancelled: true,
                phoneNumber: nil,
                idCode: nil)
            UIAccessibility.post(notification: .screenChanged, argument: L(.signingCancelled))
        }
    }

    @IBAction func signAction() {
        if rememberSwitch.isOn {
            DefaultsHelper.idCode = idCodeTextField.text ?? String()
            DefaultsHelper.phoneNumber = phoneTextField.text ?? String()
            rememberSwitch.accessibilityUserInputLabels = ["Disable remember me"]
        } else {
            DefaultsHelper.idCode = String()
            DefaultsHelper.phoneNumber = String()
            rememberSwitch.accessibilityUserInputLabels = ["Enable remember me"]
        }
        if DefaultsHelper.isRoleAndAddressEnabled {
            let roleAndAddressView = UIStoryboard.tokenFlow.instantiateViewController(of: RoleAndAddressViewController.self)
            roleAndAddressView.modalPresentationStyle = .overCurrentContext
            roleAndAddressView.modalTransitionStyle = .crossDissolve
            roleAndAddressView.viewController = self
            present(roleAndAddressView, animated: true)
        } else {
            dismiss(animated: false) { [weak self] in
                self?.sign(nil)
            }
        }
    }
    
    @objc func toggleRememberMe(_ sender: UISwitch) {
        if sender.isOn {
            rememberSwitch.accessibilityUserInputLabels = ["Disable remember me"]
        } else {
            rememberSwitch.accessibilityUserInputLabels = ["Enable remember me"]
        }
    }
    
    func sign(_ pin: String?) {
        dismiss(animated: false) {
            [weak self] in
            guard let sself = self else { return }
            sself.delegate?.mobileIDEditViewControllerDidDismiss(
                cancelled: false,
                phoneNumber: sself.phoneTextField.text,
                idCode: sself.idCodeTextField.text)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        idCodeTextField.text = DefaultsHelper.idCode
        phoneTextField.text = DefaultsHelper.phoneNumber

        idCodeTextField.attributedPlaceholder = NSAttributedString(string: L(.settingsIdCodePlaceholder), attributes: [NSAttributedString.Key.foregroundColor: UIColor.moppPlaceholderDarker])
        phoneTextField.attributedPlaceholder = NSAttributedString(string: L(.settingsPhoneNumberPlaceholder), attributes: [NSAttributedString.Key.foregroundColor: UIColor.moppPlaceholderDarker])

        idCodeTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        phoneTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)

        countryCodePrefill(textField: phoneTextField, countryCode: "372")

        defaultRememberMeToggle()

        verifySigningCapability()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
    }

    deinit {
        idCodeTextField.removeTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        phoneTextField.removeTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
    }
    
    @objc func handleAccessibilityKeyboard(_ notification: NSNotification) {
        dismissKeyboard(notification)
        ViewUtil.focusOnView(notification, mainView: self.view, scrollView: scrollView)
    }

    func defaultRememberMeToggle() {
        rememberSwitch.setOn(DefaultsHelper.mobileIdRememberMe, animated: true)
        rememberSwitch.accessibilityUserInputLabels = [DefaultsHelper.mobileIdRememberMe ? "Disable remember me" : "Enable remember me"]
    }

    func verifySigningCapability() {
        let phoneField = phoneTextField.text ?? String()
        let codeTextField = idCodeTextField.text ?? String()
        if phoneField.isEmpty || codeTextField.isEmpty || !TokenFlowUtil.isCountryCodeValid(text: phoneField) || TokenFlowUtil.isPhoneNumberInvalid(text: phoneField) || TokenFlowUtil.isPersonalCodeInvalid(text: codeTextField) {
            signButton.isEnabled = false
            signButton.backgroundColor = UIColor.moppLabel
        } else {
            signButton.isEnabled = true
            signButton.backgroundColor = UIColor.moppBase
        }
    }

    @objc func editingChanged(sender: UITextField) {
        if sender.accessibilityIdentifier == "mobileIDCodeField" {
            let text = sender.text ?? String()
            if (text.count >= 11 && !PersonalCodeValidator.isPersonalCodeValid(personalCode: text)) {
                TextUtil.deleteBackward(textField: sender)
            }
        }
        verifySigningCapability()
    }
    
    override func keyboardWillShow(notification: NSNotification) {
        if phoneTextField.isFirstResponder {
            showKeyboard(textFieldLabel: phoneLabel, scrollView: scrollView)
        }
        
        if idCodeTextField.isFirstResponder {
            showKeyboard(textFieldLabel: idCodeLabel, scrollView: scrollView)
        }
    }
    
    override func keyboardWillHide(notification: NSNotification) {
        hideKeyboard(scrollView: scrollView)
    }
}

extension MobileIDEditViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.accessibilityIdentifier == "mobileIdPhoneNumberField" {
            textField.resignFirstResponder()
            if let personalCodeTextField = getViewByAccessibilityIdentifier(view: view, identifier: "mobileIDCodeField") {
                personalCodeTextField.becomeFirstResponder()
            }
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            let textAfterUpdate = text.replacingCharacters(in: range, with: string)
            return textAfterUpdate.isNumeric || textAfterUpdate.isEmpty
        }
        verifySigningCapability()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.moveCursorToEnd()
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // Verify signing capability after user has deleted a number
        if let idCodeField = textField as? PersonalCodeField {
            idCodeField.onDeleteButtonClicked = {
                self.verifySigningCapability()
            }
        }
        
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.accessibilityIdentifier == "mobileIdPhoneNumberField" {
            if let text = textField.text as String? {
                if !TokenFlowUtil.isCountryCodeValid(text: text) {
                    phoneNumberErrorLabel.text = L(.signingErrorIncorrectCountryCode)
                    phoneNumberErrorLabel.isHidden = false
                    setViewBorder(view: textField, color: .moppError)
                    UIAccessibility.post(notification: .layoutChanged, argument: self.phoneNumberErrorLabel)
                } else if TokenFlowUtil.isPhoneNumberInvalid(text: text) {
                    phoneNumberErrorLabel.text = L(.signingErrorIncorrectPhoneNumber)
                    phoneNumberErrorLabel.isHidden = false
                    setViewBorder(view: textField, color: .moppError)
                    UIAccessibility.post(notification: .layoutChanged, argument: self.phoneNumberErrorLabel)
                } else {
                    phoneNumberErrorLabel.text = ""
                    phoneNumberErrorLabel.isHidden = true
                    removeViewBorder(view: textField)
                    UIAccessibility.post(notification: .layoutChanged, argument: phoneTextField)
                }
            }
        } else if textField.accessibilityIdentifier == "mobileIDCodeField" {
            if let text = textField.text as String? {
                if TokenFlowUtil.isPersonalCodeInvalid(text: text) {
                    personalCodeErrorLabel.text = L(.signingErrorIncorrectPersonalCode)
                    personalCodeErrorLabel.isHidden = false
                    setViewBorder(view: textField, color: .moppError)
                    UIAccessibility.post(notification: .screenChanged, argument: self.personalCodeErrorLabel)
                } else {
                    personalCodeErrorLabel.text = ""
                    personalCodeErrorLabel.isHidden = true
                    removeViewBorder(view: textField)
                    UIAccessibility.post(notification: .screenChanged, argument: idCodeTextField)
                }
            }
        }
    }
}

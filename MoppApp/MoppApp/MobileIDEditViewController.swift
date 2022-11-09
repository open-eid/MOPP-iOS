//
//  MobileIDEditViewController.swift
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
import Foundation
import UIKit


class MyTextField : UITextField {
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

class MobileIDEditViewController : MoppViewController {
    @IBOutlet weak var idCodeTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var centerViewCenterCSTR: NSLayoutConstraint!
    @IBOutlet weak var centerViewOutofscreenCSTR: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var idCodeLabel: UILabel!
    @IBOutlet weak var phoneNumberErrorLabel: UILabel!
    @IBOutlet weak var personalCodeErrorLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var signButton: UIButton!
    @IBOutlet weak var rememberLabel: UILabel!
    @IBOutlet weak var rememberSwitch: UISwitch!

    weak var delegate: MobileIDEditViewControllerDelegate? = nil
    var tapGR: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()

        if isNonDefaultPreferredContentSizeCategory() || isBoldTextEnabled() {
            setCustomFont()
        }

        idCodeTextField.moppPresentDismissButton()
        phoneTextField.moppPresentDismissButton()

        titleLabel.text = L(.mobileIdTitle)
        phoneLabel.text = L(.mobileIdPhoneTitle)
        idCodeLabel.text = L(.mobileIdIdcodeTitle)
        cancelButton.setTitle(L(.actionCancel).uppercased())
        signButton.setTitle(L(.actionSign).uppercased())
        rememberLabel.text = L(.signingRememberMe)

        phoneNumberErrorLabel.text = ""
        phoneNumberErrorLabel.isHidden = true
        personalCodeErrorLabel.text = ""
        personalCodeErrorLabel.isHidden = true

        idCodeTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        idCodeTextField.layer.borderWidth = 1.0

        phoneTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        phoneTextField.layer.borderWidth = 1.0

        tapGR = UITapGestureRecognizer()
        tapGR.addTarget(self, action: #selector(cancelAction))
        view.addGestureRecognizer(tapGR)

        guard let titleUILabel = titleLabel, let phoneUILabel = phoneLabel, let phoneUITextField = phoneTextField, let phoneNumberErrorUILabel = phoneNumberErrorLabel, let idCodeUILabel = idCodeLabel, let idCodeUITextField = idCodeTextField, let personalCodeUIErrorLabel = personalCodeErrorLabel, let rememberUILabel = rememberLabel, let rememberUISwitch = rememberSwitch, let cancelUIButton = cancelButton, let signUIButton = signButton else {
            printLog("Unable to get titleLabel, phoneLabel, phoneTextField, phoneNumberErrorLabel, idCodeLabel, idCodeTextField, personalCodeErrorLabel, rememberLabel, rememberSwitch, cancelButton or signButton")
            return
        }

        self.view.accessibilityElements = [titleUILabel, phoneUILabel, phoneUITextField, phoneNumberErrorUILabel, idCodeUILabel, idCodeUITextField, personalCodeUIErrorLabel, rememberUILabel, rememberUISwitch, cancelUIButton, signUIButton]
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
        }
        else {
            DefaultsHelper.idCode = String()
            DefaultsHelper.phoneNumber = String()
        }
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

    func defaultRememberMeToggle() {
        if (DefaultsHelper.phoneNumber?.count ?? 0 > 0 && DefaultsHelper.idCode.count > 0) {
            rememberSwitch.setOn(true, animated: true)
        } else {
            rememberSwitch.setOn(false, animated: true)
        }
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

    func setCustomFont() {
        titleLabel.font = UIFont.setCustomFont(font: .regular, isNonDefaultPreferredContentSizeCategoryBigger() ? nil : 19, .body)
        phoneLabel.font = UIFont.setCustomFont(font: .regular, nil, .body)
        idCodeLabel.font = UIFont.setCustomFont(font: .regular, nil, .body)
        cancelButton.titleLabel?.font = UIFont.setCustomFont(font: .regular, isNonDefaultPreferredContentSizeCategoryBigger() ? 12 : nil, .body)
        signButton.titleLabel?.font = UIFont.setCustomFont(font: .regular, isNonDefaultPreferredContentSizeCategoryBigger() ? 12 : nil, .body)
        rememberLabel.font = UIFont.setCustomFont(font: .regular, isNonDefaultPreferredContentSizeCategoryBigger() ? 12 : nil, .body)
        idCodeTextField.font = UIFont.setCustomFont(font: .regular, isNonDefaultPreferredContentSizeCategoryBigger() ? 14 : nil, .body)
        phoneTextField.font = UIFont.setCustomFont(font: .regular, isNonDefaultPreferredContentSizeCategoryBigger() ? 14 : nil, .body)

        signButton.sizeToFit()

    }

    @objc func editingChanged(sender: UITextField) {
        verifySigningCapability()
        if sender.accessibilityIdentifier == "mobileIDCodeField" {
            let text = sender.text ?? String()
            if (text.count > 11) {
                sender.deleteBackward()
            }
        }
    }
}

extension MobileIDEditViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            let textAfterUpdate = text.replacingCharacters(in: range, with: string)
            return textAfterUpdate.isNumeric || textAfterUpdate.isEmpty
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
                    UIAccessibility.post(notification: .screenChanged, argument: self.phoneNumberErrorLabel)
                } else if TokenFlowUtil.isPhoneNumberInvalid(text: text) {
                    phoneNumberErrorLabel.text = L(.signingErrorIncorrectPhoneNumber)
                    phoneNumberErrorLabel.isHidden = false
                    setViewBorder(view: textField, color: .moppError)
                    UIAccessibility.post(notification: .screenChanged, argument: self.phoneNumberErrorLabel)
                } else {
                    phoneNumberErrorLabel.text = ""
                    phoneNumberErrorLabel.isHidden = true
                    removeViewBorder(view: textField)
                    UIAccessibility.post(notification: .screenChanged, argument: phoneTextField)
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

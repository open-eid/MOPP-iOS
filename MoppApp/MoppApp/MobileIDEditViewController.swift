//
//  MobileIDEditViewController.swift
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

protocol MobileIDEditViewControllerDelegate : class {
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
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var signButton: UIButton!
    @IBOutlet weak var rememberLabel: UILabel!
    @IBOutlet weak var rememberSwitch: UISwitch!
    
    weak var delegate: MobileIDEditViewControllerDelegate? = nil
    var tapGR: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        idCodeTextField.moppPresentDismissButton()
        phoneTextField.moppPresentDismissButton()
        
        titleLabel.text = L(.mobileIdTitle)
        phoneLabel.text = L(.mobileIdPhoneTitle)
        idCodeLabel.text = L(.mobileIdIdcodeTitle)
        cancelButton.setTitle(L(.actionCancel).uppercased())
        signButton.setTitle(L(.actionSign).uppercased())
        rememberLabel.text = L(.mobileIdRememberMe)
        
        idCodeTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        idCodeTextField.layer.borderWidth = 1.0
        
        phoneTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        phoneTextField.layer.borderWidth = 1.0
        
        tapGR = UITapGestureRecognizer()
        tapGR.addTarget(self, action: #selector(cancelAction))
        view.addGestureRecognizer(tapGR)
        
        self.view.accessibilityElements = [titleLabel, phoneLabel, phoneTextField, idCodeLabel, idCodeTextField, rememberLabel, rememberSwitch, cancelButton, signButton]
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
        
        idCodeTextField.attributedPlaceholder = NSAttributedString(string: L(.settingsIdCodePlaceholder), attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)])
        phoneTextField.attributedPlaceholder = NSAttributedString(string: L(.settingsPhoneNumberPlaceholder), attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)])
        
        idCodeTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        
        rememberSwitch.setOn(false, animated: true)
        
        countryCodePrefill(textField: phoneTextField, countryCode: "372")
        
        verifySigningCapability()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
    }
    
    deinit {
        idCodeTextField.removeTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
    }
    
    func verifySigningCapability() {
        let textField = idCodeTextField.text ?? String()
        if (idCodeTextField.text.isNilOrEmpty || textField.count < 11) {
            signButton.isEnabled = false
            signButton.backgroundColor = UIColor.moppLabel
        } else {
            signButton.isEnabled = true
            signButton.backgroundColor = UIColor.moppBase
        }
    }
    
    @objc func editingChanged(sender: UITextField) {
        let text = sender.text ?? String()
        verifySigningCapability()
        if (text.count > 11) {
            sender.deleteBackward()
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
}

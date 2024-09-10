//
//  NFCEditViewController.swift
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

import UIKit
import CoreNFC

protocol NFCEditViewControllerDelegate : AnyObject {
    func nfcEditViewControllerDidDismiss(cancelled: Bool, can: String?, pin: String?)
}

class NFCEditViewController : MoppViewController, TokenFlowSigning {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var canTextField: UITextField!
    @IBOutlet weak var pinTextField: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var canTextLabel: UILabel!
    @IBOutlet weak var pinTextLabel: UILabel!
    @IBOutlet weak var canTextInfoLabel: ScaledLabel!
    @IBOutlet weak var pinTextErrorLabel: UILabel!
    @IBOutlet weak var cancelButton: MoppButton!
    @IBOutlet weak var signButton: MoppButton!
    
    static private let nfcCANKey = "nfcCANKey"
    static private let nfcCANKeyFilename = "canKey.txt"
    weak var delegate: NFCEditViewControllerDelegate? = nil
    var tapGR: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let notAvailable = !NFCTagReaderSession.readingAvailable

        titleLabel.text = notAvailable ? L(.nfcDeviceNoSupport) : L(.nfcTitle)
        canTextLabel.text = L(.nfcCANTitle)
        canTextLabel.isHidden = notAvailable
        pinTextLabel.text = L(.pin2TextfieldLabel)
        pinTextLabel.isHidden = notAvailable

        setCANDefaultText()

        pinTextErrorLabel.text = ""
        pinTextErrorLabel.isHidden = true
        
        canTextLabel.textColor = UIColor.moppText
        pinTextLabel.textColor = UIColor.moppText

        canTextField.moppPresentDismissButton()
        canTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        canTextField.layer.borderWidth = 1.0
        canTextField.delegate = self
        canTextField.isHidden = notAvailable
        pinTextField.moppPresentDismissButton()
        pinTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        pinTextField.layer.borderWidth = 1.0
        pinTextField.delegate = self
        pinTextField.isHidden = notAvailable

        cancelButton.setTitle(L(.actionCancel).uppercased())
        cancelButton.adjustedFont()
        signButton.setTitle(L(.actionSign).uppercased())
        signButton.adjustedFont()

        tapGR = UITapGestureRecognizer()
        tapGR.addTarget(self, action: #selector(cancelAction))
        view.addGestureRecognizer(tapGR)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let canNumber = canTextField.text {
            if !canNumber.isEmpty && canNumber.count != 6 {
                setCANErrorText()
            } else {
                setCANDefaultText()
            }
        } else {
            setCANDefaultText()
        }
    }

    @objc func dismissKeyboard(_ notification: NSNotification) {
        pinTextField.resignFirstResponder()
        canTextField.resignFirstResponder()
    }

    @IBAction func cancelAction() {
        dismiss(animated: false) {
            [weak self] in
            guard let sself = self else { return }
            sself.delegate?.nfcEditViewControllerDidDismiss(
                cancelled: true,
                can: nil,
                pin: nil)
            UIAccessibility.post(notification: .screenChanged, argument: L(.signingCancelled))
        }
    }

    @IBAction func signAction() {
        if DefaultsHelper.isRoleAndAddressEnabled {
            let roleAndAddressView = UIStoryboard.tokenFlow.instantiateViewController(of: RoleAndAddressViewController.self)
            roleAndAddressView.modalPresentationStyle = .overCurrentContext
            roleAndAddressView.modalTransitionStyle = .crossDissolve
            roleAndAddressView.viewController = self
            present(roleAndAddressView, animated: true)
        } else {
            sign(nil)
        }
    }

    func sign(_ pin: String?) {
        dismiss(animated: false) {
            [weak self] in
            guard let sself = self else { return }
            sself.delegate?.nfcEditViewControllerDidDismiss(
                cancelled: false,
                can: sself.canTextField.text,
                pin: sself.pinTextField.text)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        do {
            let nfcCanKey = KeychainUtil.retrieve(key: NFCEditViewController.nfcCANKey)
            let symmetricKey = try EncryptedDataUtil.getSymmetricKey(fileName: NFCEditViewController.nfcCANKeyFilename)
            if let canKey = nfcCanKey {
                canTextField.text = EncryptedDataUtil.decryptSecret(canKey, with: symmetricKey)
            }
        } catch let error {
            printLog("Unable to get stored 'CAN number' symmetric key: \(error.localizedDescription)")
        }

        pinTextField.text = ""

        canTextField.attributedPlaceholder = NSAttributedString(string: "CAN", attributes: [NSAttributedString.Key.foregroundColor: UIColor.moppPlaceholderDarker])
        pinTextField.attributedPlaceholder = NSAttributedString(string: "PIN2", attributes: [NSAttributedString.Key.foregroundColor: UIColor.moppPlaceholderDarker])

        canTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        pinTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)

        canTextField.accessibilityLabel = L(.nfcCANTitle)
        pinTextField.accessibilityLabel = L(.pin2TextfieldLabel)

        verifySigningCapability()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
    }

    deinit {
        canTextField.removeTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        pinTextField.removeTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
    }

    @objc func handleAccessibilityKeyboard(_ notification: NSNotification) {
        dismissKeyboard(notification)
        ViewUtil.focusOnView(notification, mainView: self.view, scrollView: scrollView)
    }

    func verifySigningCapability() {
        if canTextField.text?.count == 6,
           pinTextField.text?.count ?? 0 >= 5,
           pinTextField.text?.count ?? 0 <= 12 {
            signButton.isEnabled = true
            signButton.backgroundColor = UIColor.moppBase
        } else {
            signButton.isEnabled = false
            signButton.backgroundColor = UIColor.moppLabel
        }
    }

    @objc func editingChanged(sender: UITextField) {
        verifySigningCapability()
    }

    override func keyboardWillShow(notification: NSNotification) {
        if canTextField.isFirstResponder {
            showKeyboard(textFieldLabel: canTextLabel, scrollView: scrollView)
        }

        if pinTextField.isFirstResponder {
            showKeyboard(textFieldLabel: pinTextLabel, scrollView: scrollView)
        }
    }

    override func keyboardWillHide(notification: NSNotification) {
        hideKeyboard(scrollView: scrollView)
    }
    
    func setCANDefaultText() {
        canTextInfoLabel.text = L(.nfcCanLocation)
        canTextInfoLabel.isHidden = false
        canTextInfoLabel.textColor = UIColor.moppText
    }
    
    func setCANErrorText() {
        canTextInfoLabel.text = L(.nfcIncorrectLength)
        canTextInfoLabel.isHidden = false
        canTextInfoLabel.textColor = UIColor.moppError
    }
}

extension NFCEditViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField.accessibilityIdentifier == "nfcCanField" else {
            textField.resignFirstResponder()
            return true
        }
        textField.resignFirstResponder()
        if let pinTextField = getViewByAccessibilityIdentifier(view: view, identifier: "nfcPinField") {
            pinTextField.becomeFirstResponder()
        }
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            let textAfterUpdate = text.replacingCharacters(in: range, with: string)
            return textAfterUpdate.isNumeric || textAfterUpdate.isEmpty
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.moveCursorToEnd()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.accessibilityIdentifier == "nfcCanField" {
            if let can = textField.text {
                if !can.isEmpty && can.count != 6 {
                    setCANErrorText()
                } else {
                    setCANDefaultText()
                }
                do {
                    let symKey = try EncryptedDataUtil.getSymmetricKey(fileName: NFCEditViewController.nfcCANKeyFilename)
                    if let encryptedKey = EncryptedDataUtil.encryptSecret(can, with: symKey) {
                        _ = KeychainUtil.save(key: NFCEditViewController.nfcCANKey, info: encryptedKey, withPasscodeSetOnly: true)
                    } else {
                        printLog("Encryption failed for 'CAN' string")
                    }
                } catch {
                    do {
                        let symKeyURL = try EncryptedDataUtil.saveSymmetricKeyToAppSupport(fileName: NFCEditViewController.nfcCANKeyFilename)
                        let symKey = try EncryptedDataUtil.getSymmetricKey(fileName: symKeyURL.lastPathComponent)
                        
                        if let encryptedKey = EncryptedDataUtil.encryptSecret(can, with: symKey) {
                            _ = KeychainUtil.save(key: NFCEditViewController.nfcCANKey, info: encryptedKey, withPasscodeSetOnly: true)
                        } else {
                            printLog("Encryption failed for 'CAN number' after saving new symmetric key")
                        }
                    } catch {
                        printLog("Unable to save or retrieve symmetric key: \(error.localizedDescription)")
                    }
                }
            } else {
                KeychainUtil.remove(key: NFCEditViewController.nfcCANKey)
                setCANDefaultText()
                removeViewBorder(view: textField)
                UIAccessibility.post(notification: .layoutChanged, argument: canTextField)
            }
        }
        if textField.accessibilityIdentifier == "nfcPinField",
           textField.text != nil {
            pinTextErrorLabel.text = ""
            pinTextErrorLabel.isHidden = true
            removeViewBorder(view: textField)
            UIAccessibility.post(notification: .screenChanged, argument: pinTextField)
        }
    }
}

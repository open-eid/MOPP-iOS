/*
 * MoppApp - SmartIDEditViewController.swift
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

protocol SmartIDEditViewControllerDelegate : AnyObject {
    func smartIDEditViewControllerDidDismiss(cancelled: Bool, country: String?, idCode: String?)
}

class CountryTextField: MyTextField {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        return CGRect.zero
    }

    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        return []
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.copy(_:)) ||
            action == #selector(UIResponderStandardEditActions.selectAll(_:)) ||
            action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}

class SmartIDEditViewController : MoppViewController {
    @IBOutlet weak var idCodeTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var idCodeLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var signButton: UIButton!
    @IBOutlet weak var rememberLabel: UILabel!
    @IBOutlet weak var rememberSwitch: UISwitch!

    weak var delegate: SmartIDEditViewControllerDelegate? = nil
    var tapGR: UITapGestureRecognizer!
    var countryViewPicker = UIPickerView()
    
    @IBAction func openCountryPicker(_ sender: Any) {
        UIAccessibility.post(notification: .layoutChanged, argument: countryViewPicker)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = L(.smartIdTitle)
        countryLabel.text = L(.smartIdCountryTitle)
        idCodeLabel.text = L(.mobileIdIdcodeTitle)
        cancelButton.setTitle(L(.actionCancel).uppercased())
        signButton.setTitle(L(.actionSign).uppercased())
        rememberLabel.text = L(.signingRememberMe)

        idCodeTextField.moppPresentDismissButton()
        idCodeTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        idCodeTextField.layer.borderWidth = 1.0

        countryViewPicker.dataSource = self
        countryViewPicker.delegate = self
        let pickerToolbar = UIToolbar()
        pickerToolbar.barStyle = .default
        pickerToolbar.isUserInteractionEnabled = true
        pickerToolbar.items = [
            UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target:self, action:nil),
            UIBarButtonItem(barButtonSystemItem:.done, target: self, action: #selector(pickerDoneButtonTapped))
        ]
        pickerToolbar.sizeToFit()
        countryTextField.inputAccessoryView = pickerToolbar
        countryTextField.inputView = countryViewPicker
        countryTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        countryTextField.layer.borderWidth = 1.0

        tapGR = UITapGestureRecognizer()
        tapGR.addTarget(self, action: #selector(cancelAction))
        view.addGestureRecognizer(tapGR)
        
        guard let titleUILabel = titleLabel, let countryUILabel = countryLabel, let countryUITextField = countryTextField, let idCodeUILabel = idCodeLabel, let idCodeUITextField = idCodeTextField, let rememberUILabel = rememberLabel, let rememberUISwitch = rememberSwitch, let cancelUIButton = cancelButton, let signUIButton = signButton else {
            NSLog("Unable to get titleLabel, countryLabel, countryTextField, idCodeLabel, idCodeTextField, rememberLabel, rememberSwitch, cancelButton or signButton")
            return
        }

        view.accessibilityElements = [titleUILabel, countryUILabel, countryUITextField, idCodeUILabel, idCodeUITextField, rememberUILabel, rememberUISwitch, cancelUIButton, signUIButton]
    }

    @objc func dismissKeyboard(_ notification: NSNotification) {
        idCodeTextField.resignFirstResponder()
        countryTextField.resignFirstResponder()
    }

    @objc func pickerDoneButtonTapped() {
        self.countryTextField.endEditing(true)
    }

    @objc func codeDoneButtonTapped() {
        self.idCodeTextField.endEditing(true)
    }

    @objc func codeDashButtonTapped() {
        let text = self.idCodeTextField.text ?? ""
        self.idCodeTextField.text = text + "-"
    }

    @IBAction func editingChanged(_ sender: UITextField) {
        verifySigningCapability()
        let text = sender.text ?? String()
        if countryViewPicker.selectedRow(inComponent: 0) == 0 && text.count > 11 {
            sender.deleteBackward()
        }
    }

    @IBAction func cancelAction() {
        dismiss(animated: false) { [weak self] in
            guard let sself = self else { return }
            sself.delegate?.smartIDEditViewControllerDidDismiss(cancelled: true, country: nil, idCode: nil)
            UIAccessibility.post(notification: .screenChanged, argument: L(.signingCancelled))
        }
    }

    @IBAction func signAction() {
        let country: String = {
            switch countryViewPicker.selectedRow(inComponent: 0) {
            case 1: return "LT"
            case 2: return "LV"
            default: return "EE"
            }
        }()
        if rememberSwitch.isOn {
            DefaultsHelper.sidIdCode = idCodeTextField.text ?? String()
            DefaultsHelper.sidCountry = country
        }
        else {
            DefaultsHelper.sidIdCode = String()
            DefaultsHelper.sidCountry = String()
        }
        dismiss(animated: false) { [weak self] in
            guard let sself = self else { return }
            sself.delegate?.smartIDEditViewControllerDidDismiss(cancelled: false, country: country, idCode: sself.idCodeTextField.text)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let row: Int = {
            switch DefaultsHelper.sidCountry {
            case "LT": return 1
            case "LV": return 2
            default: return 0
            }
        }()
        countryViewPicker.selectRow(row, inComponent: 0, animated: true)
        countryTextField.text = self.pickerView(countryViewPicker, titleForRow: row, forComponent: 0)
        idCodeTextField.attributedPlaceholder = NSAttributedString(string: L(.smartIdCountryTitle), attributes: [NSAttributedString.Key.foregroundColor: UIColor.moppPlaceholderDarker])
        idCodeTextField.text = DefaultsHelper.sidIdCode
        idCodeTextField.attributedPlaceholder = NSAttributedString(string: L(.settingsIdCodePlaceholder), attributes: [NSAttributedString.Key.foregroundColor: UIColor.moppPlaceholderDarker])
        rememberSwitch.setOn(DefaultsHelper.sidCountry != "EE" || DefaultsHelper.sidIdCode.count > 0, animated: true)

        verifySigningCapability()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
    }

    func verifySigningCapability() {
        let codeTextField = idCodeTextField.text ?? String()
        signButton.isEnabled = countryViewPicker.selectedRow(inComponent: 0) != 0 || codeTextField.count == 11
        signButton.backgroundColor = signButton.isEnabled ? UIColor.moppBase : UIColor.moppLabel
    }
}

extension SmartIDEditViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 3
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch row {
        case 1: return L(.smartIdCountryLithuania)
        case 2: return L(.smartIdCountryLatvia)
        default: return L(.smartIdCountryEstonia)
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        countryTextField.text = self.pickerView(pickerView, titleForRow: row, forComponent: component)
        countryTextField.accessibilityLabel = ""
        UIAccessibility.post(notification: .announcement, argument: countryTextField.text)
        var codeToolbar: UIToolbar? = nil
        if row != 0 {
            codeToolbar = UIToolbar()
            codeToolbar?.barStyle = .default
            codeToolbar?.isUserInteractionEnabled = true
            codeToolbar?.items = [
                UIBarButtonItem(title: "-", style:.plain, target: self, action: #selector(codeDashButtonTapped)),
                UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target:self, action:nil),
                UIBarButtonItem(barButtonSystemItem:.done, target: self, action: #selector(codeDoneButtonTapped))
            ]
            codeToolbar?.sizeToFit()
        }
        idCodeTextField.inputAccessoryView = codeToolbar
        idCodeTextField.reloadInputViews()

        if row == 0 {
            idCodeTextField.text = idCodeTextField.text?.filter("0123456789.".contains).substr(offset: 0, count: 11)
        }
        verifySigningCapability()
    }
}

extension SmartIDEditViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if countryViewPicker.selectedRow(inComponent: 0) != 0 {
            return true
        }
        if let text = textField.text as NSString? {
            let textAfterUpdate = text.replacingCharacters(in: range, with: string)
            return textAfterUpdate.isNumeric || textAfterUpdate.isEmpty
        }
        return true
    }
}

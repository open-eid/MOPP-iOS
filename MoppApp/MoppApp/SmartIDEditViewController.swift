//
//  SmartIDEditViewController.swift
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

protocol SmartIDEditViewControllerDelegate : class {
    func smartIDEditViewControllerDidDismiss(cancelled: Bool, country: String?, idCode: String?)
}

class SmartIDEditViewController : MoppViewController {
    @IBOutlet weak var idCodeTextField: UITextField!
    @IBOutlet weak var countryViewPicker: UIPickerView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var idCodeLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var signButton: UIButton!
    @IBOutlet weak var rememberLabel: UILabel!
    @IBOutlet weak var rememberSwitch: UISwitch!

    weak var delegate: SmartIDEditViewControllerDelegate? = nil
    var tapGR: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = L(.smartIdTitle)
        countryLabel.text = L(.smartIdCountryTitle)
        idCodeLabel.text = L(.mobileIdIdcodeTitle)
        cancelButton.setTitle(L(.actionCancel).uppercased())
        signButton.setTitle(L(.actionSign).uppercased())
        rememberLabel.text = L(.mobileIdRememberMe)

        idCodeTextField.moppPresentDismissButton()
        idCodeTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        idCodeTextField.layer.borderWidth = 1.0

        countryViewPicker.layer.borderColor = UIColor.moppContentLine.cgColor
        countryViewPicker.layer.borderWidth = 1.0

        tapGR = UITapGestureRecognizer()
        tapGR.addTarget(self, action: #selector(cancelAction))
        view.addGestureRecognizer(tapGR)

        view.accessibilityElements = [titleLabel, countryLabel, countryViewPicker, idCodeLabel, idCodeTextField, rememberLabel, rememberSwitch, cancelButton, signButton]
    }

    @objc func dismissKeyboard(_ notification: NSNotification) {
        idCodeTextField.resignFirstResponder()
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

        switch DefaultsHelper.sidCountry {
        case "LT": countryViewPicker.selectRow(1, inComponent: 0, animated: true)
        case "LV": countryViewPicker.selectRow(2, inComponent: 0, animated: true)
        default: countryViewPicker.selectRow(0, inComponent: 0, animated: true)
        }
        idCodeTextField.text = DefaultsHelper.sidIdCode
        idCodeTextField.attributedPlaceholder = NSAttributedString(string: L(.settingsIdCodePlaceholder), attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)])
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
        default: return L(.smartIdCountryEstiona)
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        idCodeTextField.keyboardType = row == 0 ? .numberPad : .default
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

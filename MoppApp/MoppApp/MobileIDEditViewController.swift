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
        
        titleLabel.text = L(.mobileIdTitle)
        phoneLabel.text = L(.mobileIdPhoneTitle)
        idCodeLabel.text = L(.mobileIdIdcodeTitle)
        cancelButton.localizedTitle = LocKey.mobileIdCancelButtonTitle
        signButton.localizedTitle = LocKey.mobileIdSignButtonTitle
        rememberLabel.text = L(.mobileIdRememberMe)
        
        idCodeTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        idCodeTextField.layer.borderWidth = 1.0
        
        phoneTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        phoneTextField.layer.borderWidth = 1.0
        
        tapGR = UITapGestureRecognizer()
        tapGR.addTarget(self, action: #selector(cancelAction))
        view.addGestureRecognizer(tapGR)
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
    
        let idCode = DefaultsHelper.idCode
    
        idCodeTextField.text = DefaultsHelper.idCode
        phoneTextField.text = DefaultsHelper.phoneNumber
    
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        UIView.animate(withDuration: 0.35) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
        
        centerViewCenterCSTR.priority = .defaultLow
        centerViewOutofscreenCSTR.priority = .defaultHigh
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: {
            self.centerViewCenterCSTR.priority = .defaultHigh
            self.centerViewOutofscreenCSTR.priority = .defaultLow
            self.view.layoutIfNeeded()
        }) { _ in
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
    }
}

extension MobileIDEditViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

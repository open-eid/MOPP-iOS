//
//  RoleAndAddressViewController.swift
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

class RoleAndAddressViewController : MoppViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var roleTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var zipTextField: UITextField!
    
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var zipLabel: UILabel!
    
    @IBOutlet weak var signButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var buttonsBottomConstraint: NSLayoutConstraint!
    
    var tapGR: UITapGestureRecognizer!
    
    var viewController: TokenFlowSigning? = nil
    
    var selectedTextField = UITextField()
    var isShowingKeyboard = false
    
    @IBAction func signAction(_ sender: Any) {
        let roleName = roleTextField.text ?? ""
        let roleCity = cityTextField.text ?? ""
        let roleState = stateTextField.text ?? ""
        let roleCountry = countryTextField.text ?? ""
        let roleZip = zipTextField.text ?? ""
        
        let roleNames = roleName.components(separatedBy: ",")
        var roles: [String] = []
        
        for role in roleNames {
            roles.append(role.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
        }
        
        let roleData = MoppLibRoleAddressData(roles: roles, city: roleCity, state: roleState, country: roleCountry, zip: roleZip)
        
        RoleAndAddressUtil.saveRoleInfo(roleData: roleData)
        
        dismiss(animated: false) {
            [weak self] in
            guard let sself = self,
                  let selectionVC = sself.viewController else { return }
            selectionVC.sign(nil)
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: false) {
            UIAccessibility.post(notification: .screenChanged, argument: L(.signingCancelled))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let savedRoleInfo = RoleAndAddressUtil.getSavedRoleInfo()
        roleTextField.text = savedRoleInfo.roles.joined(separator: ", ")
        cityTextField.text = savedRoleInfo.city
        stateTextField.text = savedRoleInfo.state
        countryTextField.text = savedRoleInfo.country
        zipTextField.text = savedRoleInfo.zip
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        roleTextField.moppPresentDismissButton()
        cityTextField.moppPresentDismissButton()
        stateTextField.moppPresentDismissButton()
        countryTextField.moppPresentDismissButton()
        zipTextField.moppPresentDismissButton()
        
        roleTextField.delegate = self
        cityTextField.delegate = self
        stateTextField.delegate = self
        countryTextField.delegate = self
        zipTextField.delegate = self
        
        titleLabel.text = L(.roleAndAddressTitle)
        
        roleLabel.text = L(.roleAndAddressRoleTitle)
        cityLabel.text = L(.roleAndAddressCityTitle)
        stateLabel.text = L(.roleAndAddressStateTitle)
        countryLabel.text = L(.roleAndAddressCountryTitle)
        zipLabel.text = L(.roleAndAddressZipTitle)
        
        cancelButton.setTitle(L(.actionCancel).uppercased())
        signButton.setTitle(L(.actionSign).uppercased())
        
        setTextFieldBorder(textField: roleTextField)
        setTextFieldBorder(textField: cityTextField)
        setTextFieldBorder(textField: stateTextField)
        setTextFieldBorder(textField: countryTextField)
        setTextFieldBorder(textField: zipTextField)
        
        tapGR = UITapGestureRecognizer()
        tapGR.addTarget(self, action: #selector(cancelAction))
        view.addGestureRecognizer(tapGR)
        
        roleLabel.isAccessibilityElement = false
        cityLabel.isAccessibilityElement = false
        stateLabel.isAccessibilityElement = false
        countryLabel.isAccessibilityElement = false
        zipLabel.isAccessibilityElement = false
        
        roleTextField.accessibilityLabel = L(.roleAndAddressRoleTitle)
        cityTextField.accessibilityLabel = L(.roleAndAddressCityTitle)
        stateTextField.accessibilityLabel = L(.roleAndAddressStateTitle)
        countryTextField.accessibilityLabel = L(.roleAndAddressCountryTitle)
        zipTextField.accessibilityLabel = L(.roleAndAddressZipTitle)
        
        signButton.isAccessibilityElement = true
        signButton.accessibilityLabel = L(.actionSign)
        cancelButton.isAccessibilityElement = true
        cancelButton.accessibilityLabel = L(.actionCancel)

        roleTextField.accessibilityUserInputLabels = [L(.voiceControlRoleRole)]
        cityTextField.accessibilityUserInputLabels = [L(.voiceControlRoleCity)]
        stateTextField.accessibilityUserInputLabels = [L(.voiceControlRoleState)]
        countryTextField.accessibilityUserInputLabels = [L(.voiceControlRoleCountry)]
        zipTextField.accessibilityUserInputLabels = [L(.voiceControlRoleZip)]
        
        guard let titleUILabel = titleLabel, let roleUITextField = roleTextField, let roleUILabel = roleLabel, let cityUITextField = cityTextField, let cityUILabel = cityLabel, let stateUITextField = stateTextField, let stateUILabel = stateLabel, let countryUITextField = countryTextField, let countryUILabel = countryLabel, let zipUITextField = zipTextField, let zipUILabel = zipLabel, let cancelUIButton = cancelButton, let signUIButton = signButton else {
            NSLog("Unable to get titleLabel, roleLabel, roleTextField, cityLabel, cityTextField, stateLabel, stateTextField, countryLabel, countryTextField, zipLabel, zipTextField, cancelButton or signButton")
            return
        }
        
        self.view.accessibilityElements = [titleUILabel, roleUILabel, roleUITextField, cityUILabel, cityUITextField, stateUILabel, stateUITextField, countryUILabel, countryUITextField, zipUILabel, zipUITextField, cancelUIButton, signUIButton]
    }
    
    func setTextFieldBorder(textField: UITextField) {
        textField.layer.borderColor = UIColor.moppContentLine.cgColor
        textField.layer.borderWidth = 1.0
    }
    
    func signWithMobileID(mobileIDParameters: MobileIDParameters?, roleData: MoppLibRoleAddressData?) {
        let mobileIDChallengeview = UIStoryboard.tokenFlow.instantiateViewController(of: MobileIDChallengeViewController.self)
        mobileIDChallengeview.modalPresentationStyle = .overFullScreen
        getTopViewController().present(mobileIDChallengeview, animated: false)
        
        MobileIDSignature.shared.createMobileIDSignature(
            phoneNumber: mobileIDParameters?.phoneNumber ?? "",
            nationalIdentityNumber: mobileIDParameters?.idCode ?? "",
            containerPath: mobileIDParameters?.containerPath ?? "",
            hashType: mobileIDParameters?.hashType ?? "",
            language: mobileIDParameters?.language ?? "",
            roleData: roleData)
    }
    
    func signWithSmartID(smartIDParameters: SmartIDParameters?, roleData: MoppLibRoleAddressData?) {
        let smartIDChallengeview = UIStoryboard.tokenFlow.instantiateViewController(of: SmartIDChallengeViewController.self)
        smartIDChallengeview.modalPresentationStyle = .overFullScreen
        getTopViewController().present(smartIDChallengeview, animated: false)
        
        SmartIDSignature.shared.createSmartIDSignature(
            country: smartIDParameters?.country ?? "",
            nationalIdentityNumber: smartIDParameters?.idCode ?? "",
            containerPath: smartIDParameters?.containerPath ?? "",
            hashType: smartIDParameters?.hashType ?? "",
            roleData: roleData)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func keyboardWillHide(notification: NSNotification) {
        hideKeyboard(scrollView: scrollView)
    }
    
    override func keyboardWillShow(notification: NSNotification) {
        
        let textFieldsAndLabels: [UITextField: UILabel] = [
            roleTextField: roleLabel,
            cityTextField: cityLabel,
            stateTextField: stateLabel,
            countryTextField: countryLabel,
            zipTextField: zipLabel
        ]

        if let firstResponderTextField = textFieldsAndLabels.first(where: { $0.key.isFirstResponder }) {
            showKeyboard(textFieldLabel: firstResponderTextField.value, scrollView: scrollView)
        }
    }
}

extension RoleAndAddressViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        selectedTextField = textField
    }
}

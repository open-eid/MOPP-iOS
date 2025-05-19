//
//  MyeIDChangeCodesViewController.swift
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
class MyeIDChangeCodesViewController: MoppViewController {
    @IBOutlet weak var ui: MyeIDChangeCodesViewControllerUI!
    var model = MyeIDChangeCodesModel()
    
    weak var infoManager: MyeIDInfoManager!
    
    private var loadingViewController: MyeIDChangeCodesLoadingViewController! = {
        let loadingViewController = UIStoryboard.myEID.instantiateViewController(of: MyeIDChangeCodesLoadingViewController.self)
            loadingViewController.modalPresentationStyle = .overFullScreen
        return loadingViewController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LandingViewController.shared.presentButtons([])
        ui.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ui.setupWithModel(model, self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        setAccessibility(isElement: false)
    }
    
    func setAccessibility(isElement: Bool) {
        for subview in view.subviews {
            if subview.isKind(of: UIView.self) {
                subview.isAccessibilityElement = false
            } else {
                subview.isAccessibilityElement = isElement
            }
        }
    }
}

extension MyeIDChangeCodesViewController: MyeIDChangeCodesViewControllerUIDelegate {
    func didTapDiscardButton(_ ui: MyeIDChangeCodesViewControllerUI) {
        if UIAccessibility.isVoiceOverRunning {
            infoManager.actionKind = self.model.actionType
        }
        _ = navigationController?.popViewController(animated: true)
    }
    
    func didTapConfirmButton(_ ui: MyeIDChangeCodesViewControllerUI) {
        ui.clearInlineErrors()
        
        switch validateCodes() {
        case (let message, 0)?:
            ui.firstInlineErrorLabel.isHidden = false
            ui.firstInlineErrorLabel.text = message
            ui.setViewBorder(view: ui.firstCodeTextField)
            UIAccessibility.post(notification: .screenChanged, argument: ui.firstInlineErrorLabel)
            return
        case (let message, 1)?, (let message, 2)?:
            ui.secondInlineErrorLabel.isHidden = false
            ui.secondInlineErrorLabel.text = message
            ui.setViewBorder(view: ui.secondCodeTextField)
            ui.setViewBorder(view: ui.thirdCodeTextField)
            UIAccessibility.post(notification: .screenChanged, argument: ui.secondInlineErrorLabel)
            return
        default:
            break
        }

        let oldCode = ui.firstCodeTextField.text ?? String()
        let newCode = ui.secondCodeTextField.text ?? String()

        present(loadingViewController, animated: false) {
            do {
                guard let cardCommands = self.model.cardCommands else {
                    throw MoppLibError.Code.cardNotFound
                }
                var statusText = String()
                switch self.model.actionType {
                case .changePin1:
                    try cardCommands.changeCode(.pin1, to: newCode, verifyCode: oldCode)
                    statusText = L(.myEidCodeChangedSuccessMessage, [IdCardCodeName.PIN1.rawValue])
                case .changePin2:
                    try cardCommands.changeCode(.pin2, to: newCode, verifyCode: oldCode)
                    statusText = L(.myEidCodeChangedSuccessMessage, [IdCardCodeName.PIN2.rawValue])
                case .changePuk:
                    try cardCommands.changeCode(.puk, to: newCode, verifyCode: oldCode)
                    statusText = L(.myEidCodeChangedSuccessMessage, [IdCardCodeName.PUK.rawValue])
                case .unblockPin1:
                    try cardCommands.unblockCode(.pin1, puk: oldCode, newCode: newCode)
                    statusText = L(.myEidCodeUnblockedSuccessMessage, [IdCardCodeName.PIN1.rawValue])
                case .unblockPin2:
                    try cardCommands.unblockCode(.pin2, puk: oldCode, newCode: newCode)
                    statusText = L(.myEidCodeUnblockedSuccessMessage, [IdCardCodeName.PIN2.rawValue])
                }
                self.infoManager.retryCounts.resetRetryCount(for: self.model.actionType)
                self.loadingViewController.dismiss(animated: false) {
                    ui.clearCodeTextFields()
                    UIAccessibility.post(notification: .layoutChanged, argument: statusText)
                    ui.showStatusView(with: statusText)
                }
            } catch let error as NSError where error == .wrongPin {
                let retryCount = (error.userInfo[MoppLibError.kMoppLibUserInfoRetryCount] as? NSNumber)?.intValue ?? 0
                self.infoManager.retryCounts.setRetryCount(for: self.model.actionType, with: retryCount)
                self.loadingViewController.dismiss(animated: false) {
                    ui.setViewBorder(view: ui.firstCodeTextField)
                    self.ui.firstInlineErrorLabel.text =
                    L(retryCount == 1 ? .myEidWrongCodeMessageSingular : .myEidWrongCodeMessage, [self.model.actionType.codeDisplayNameForWrongOrBlocked])
                    self.ui.firstInlineErrorLabel.isHidden = false
                    UIAccessibility.post(notification: .layoutChanged, argument: self.ui.firstInlineErrorLabel)
                }
            } catch MoppLibError.Code.pinBlocked {
                self.infoManager.retryCounts.setRetryCount(for: self.model.actionType, with: 0)
                let codeDisplayName = self.model.actionType.codeDisplayNameForWrongOrBlocked
                self.loadingViewController.dismiss(animated: false) {
                    self.ui.clearCodeTextFields()
                    self.infoAlert(message: L(.myEidCodeBlockedMessage, [codeDisplayName, codeDisplayName])) { _ in
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch let error as NSError {
                self.loadingViewController.dismiss(animated: false) {
                    self.ui.clearCodeTextFields()
                    self.errorAlertWithLink(message: error.localizedFailureReason)
                }
            }
        }
    }
    
    func validateCodes() -> (message:String,textFieldIndex:Int)? {
    
        // let codeName = model.actionType.associatedCodeName()
    
        let firstCode = ui.firstCodeTextField.text ?? String()
        let secondCode = ui.secondCodeTextField.text ?? String()
        let thirdCode = ui.thirdCodeTextField.text ?? String()
        
        let personalCode = infoManager.personalData?.personalIdentificationCode ?? String()
        
        let generalNewCodeValidation = { [weak self] (value:String, codeName:String, textFieldIndex:Int) -> (message:String, textFieldIndex:Int)? in
            guard let strongSelf = self else { return nil }
            if personalCode.contains(value) {
                return (message:L(.myEidErrorCodeContainedInPersonalCode, [codeName]), textFieldIndex:textFieldIndex)
            }
            
            if strongSelf.infoManager.isNewCodeBirthdateVariant(value) ?? false {
                return (message:L(.myEidErrorCodeIsDateOfBirth, [codeName]), textFieldIndex:textFieldIndex)
            }
            
            if value.isDigitsGrowingOrShrinking || value.containsSameDigits {
                return (message:L(.myEidErrorCodeTooEasy, [codeName]), textFieldIndex:textFieldIndex)
            }
            
            return nil
        }
        
        let validateCurrentPin1 = { (value:String) -> (message:String, textFieldIndex:Int)? in
            if value.count < IdCardCodeLengthLimits.pin1Minimum.rawValue {
                return (message:L(.myEidErrorCurrentCodeTooShort, [IdCardCodeName.PIN1.rawValue, IdCardCodeLengthLimits.pin1Minimum.rawValue]), textFieldIndex:0)
            }
            return nil
        }
        
        let validateNewPin1 = { (value:String) -> (message:String, textFieldIndex:Int)? in
            if value.count < IdCardCodeLengthLimits.pin1Minimum.rawValue {
                return (message:L(.myEidErrorNewCodeTooShort, [IdCardCodeName.PIN1.rawValue, IdCardCodeLengthLimits.pin1Minimum.rawValue]), textFieldIndex:1)
            }
            else if value == firstCode {
                return (message:L(.myEidErrorCodesAreSame, [IdCardCodeName.PIN1.rawValue]), textFieldIndex:1)
            }
            return generalNewCodeValidation(value, IdCardCodeName.PIN1.rawValue, 1)
        }
        
        let validateNewControlPin1 = { (value:String) -> (message:String, textFieldIndex:Int)? in
            if value != secondCode {
                return (message:L(.myEidErrorCodesMismatch, [IdCardCodeName.PIN1.rawValue]), textFieldIndex:2)
            }
            return nil
        }
        
        let validateCurrentPin2 = { (value:String) -> (message:String, textFieldIndex:Int)? in
            if value.count < IdCardCodeLengthLimits.pin2Minimum.rawValue {
                return (message:L(.myEidErrorCurrentCodeTooShort, [IdCardCodeName.PIN2.rawValue, IdCardCodeLengthLimits.pin2Minimum.rawValue]), textFieldIndex:0)
            }
            return nil
        }
        
        let validateNewPin2 = { (value:String) -> (message:String, textFieldIndex:Int)? in
            if value.count < IdCardCodeLengthLimits.pin2Minimum.rawValue {
                return (message:L(.myEidErrorNewCodeTooShort, [IdCardCodeName.PIN2.rawValue, IdCardCodeLengthLimits.pin2Minimum.rawValue]), textFieldIndex:1)
            }
            else if value == firstCode {
                return (message:L(.myEidErrorCodesAreSame, [IdCardCodeName.PIN2.rawValue]), textFieldIndex:1)
            }
            return generalNewCodeValidation(value, IdCardCodeName.PIN2.rawValue, 1)
        }
        
        let validateNewControlPin2 = { (value:String) -> (message:String, textFieldIndex:Int)? in
            if value != secondCode {
                return (message:L(.myEidErrorCodesMismatch, [IdCardCodeName.PIN2.rawValue]), textFieldIndex:2)
            }
            return nil
        }
        
        let validateCurrentPuk = { (value:String) -> (message:String, textFieldIndex:Int)? in
            if value.count < IdCardCodeLengthLimits.pukMinimum.rawValue {
                return (message:L(.myEidErrorCurrentCodeTooShort, [IdCardCodeName.PUK.rawValue, IdCardCodeLengthLimits.pukMinimum.rawValue]), textFieldIndex:0)
            }
            return nil
        }
        
        let validateNewPuk = { (value:String) -> (message:String, textFieldIndex:Int)? in
            if value.count < IdCardCodeLengthLimits.pukMinimum.rawValue {
                return (message:L(.myEidErrorNewCodeTooShort, [IdCardCodeName.PUK.rawValue, IdCardCodeLengthLimits.pukMinimum.rawValue]), textFieldIndex:1)
            }
            else if value == firstCode {
                return (message:L(.myEidErrorCodesAreSame, [IdCardCodeName.PUK.rawValue]), textFieldIndex:1)
            }
            return generalNewCodeValidation(value, IdCardCodeName.PUK.rawValue, 1)
        }
        
        let validateNewControlPuk = { (value:String) -> (message:String, textFieldIndex:Int)? in
            if value != secondCode {
                return (message:L(.myEidErrorCodesMismatch, [IdCardCodeName.PUK.rawValue]), textFieldIndex:2)
            }
            return nil
        }
        
        if model.actionType == .changePin1 {
            if let errorMessage = validateCurrentPin1(firstCode) { return errorMessage }
            if let errorMessage = validateNewPin1(secondCode) { return errorMessage }
            if let errorMessage = validateNewControlPin1(thirdCode) { return errorMessage }
        }
        else if model.actionType == .unblockPin1 {
            if let errorMessage = validateCurrentPuk(firstCode) { return errorMessage }
            if let errorMessage = validateNewPin1(secondCode) { return errorMessage }
            if let errorMessage = validateNewControlPin1(thirdCode) { return errorMessage }
        }
        else if model.actionType == .changePin2 {
            if let errorMessage = validateCurrentPin2(firstCode) { return errorMessage }
            if let errorMessage = validateNewPin2(secondCode) { return errorMessage }
            if let errorMessage = validateNewControlPin2(thirdCode) { return errorMessage }
        }
        else if model.actionType == .unblockPin2 {
            if let errorMessage = validateCurrentPuk(firstCode) { return errorMessage }
            if let errorMessage = validateNewPin2(secondCode) { return errorMessage }
            if let errorMessage = validateNewControlPin2(thirdCode) { return errorMessage }
        }
        else if model.actionType == .changePuk {
            if let errorMessage = validateCurrentPuk(firstCode) { return errorMessage }
            if let errorMessage = validateNewPuk(secondCode) { return errorMessage }
            if let errorMessage = validateNewControlPuk(thirdCode) { return errorMessage }
        }
        
        return nil
    }
}

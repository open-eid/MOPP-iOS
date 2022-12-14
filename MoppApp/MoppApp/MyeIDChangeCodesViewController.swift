//
//  MyeIDChangeCodesViewController.swift
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
    }
}

extension MyeIDChangeCodesViewController: MyeIDChangeCodesViewControllerUIDelegate {
    func didTapDiscardButton(_ ui: MyeIDChangeCodesViewControllerUI) {
        if UIAccessibility.isVoiceOverRunning {
            switch self.model.actionType {
            case .changePin1:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .screenChanged, argument: L(.myEidInfoPin1ChangeCancelled))
                }
            case .unblockPin1:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .screenChanged, argument: L(.myEidInfoPin1UnblockCancelled))
                }
            case .changePin2:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .screenChanged, argument: L(.myEidInfoPin2ChangeCancelled))
                }
            case .unblockPin2:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .screenChanged, argument: L(.myEidInfoPin2UnblockCancelled))
                }
            case .changePuk:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .screenChanged, argument: L(.myEidInfoPukChangeCancelled))
                }
            }
        }
        _ = navigationController?.popViewController(animated: true)
    }
    
    func didTapConfirmButton(_ ui: MyeIDChangeCodesViewControllerUI) {
        let failureClosure = { [weak self] (error: Error?) in
            guard let strongSelf = self else { return }

            var showErrorInline = false
            var errorMessage = L(.genericErrorMessage)
            if let nsError = error as NSError? {
                let actionType = strongSelf.model.actionType
                var errorCode:UInt = UInt(nsError.code)
                
                let retryCount = (nsError.userInfo[kMoppLibUserInfoRetryCount] as? NSNumber)?.intValue ?? 0
                if errorCode == MoppLibErrorCode.moppLibErrorWrongPin.rawValue && retryCount == 0 {
                    errorCode = MoppLibErrorCode.moppLibErrorPinBlocked.rawValue
                }
                
                if errorCode == MoppLibErrorCode.moppLibErrorWrongPin.rawValue {
                    let retryCount = (nsError.userInfo[kMoppLibUserInfoRetryCount] as? NSNumber)?.intValue ?? 0
                    strongSelf.infoManager.retryCounts.setRetryCount(for: actionType, with: retryCount)
                    if retryCount == 1 {
                        errorMessage = L(.myEidWrongCodeMessageSingular, [actionType.codeDisplayNameForWrongOrBlocked])
                        showErrorInline = true
                    }
                    else {
                        errorMessage = L(.myEidWrongCodeMessage, [actionType.codeDisplayNameForWrongOrBlocked])
                        showErrorInline = true
                    }
                    ui.setViewBorder(view: ui.firstCodeTextField)
                }
                else if errorCode == MoppLibErrorCode.moppLibErrorPinBlocked.rawValue {
                    strongSelf.infoManager.retryCounts.setRetryCount(for: actionType, with: 0)
                    let codeDisplayName = actionType.codeDisplayNameForWrongOrBlocked
                    errorMessage = L(.myEidCodeBlockedMessage, [codeDisplayName, codeDisplayName])
                }
                else if let localizedReason = nsError.userInfo[NSLocalizedFailureReasonErrorKey.self] as? String {
                    self?.loadingViewController.dismiss(animated: false, completion: {
                        self?.errorAlert(message: localizedReason)
                    })
                }
            }
            self?.loadingViewController.dismiss(animated: false, completion: {
                self?.ui.clearCodeTextFields()
                if showErrorInline {
                    self?.ui.firstInlineErrorLabel.text = errorMessage
                    self?.ui.firstInlineErrorLabel.isHidden = false
                    UIAccessibility.post(notification: .layoutChanged, argument: self?.ui.firstInlineErrorLabel)
                } else {
                    self?.errorAlert(message: errorMessage, title: nil, dismissCallback: { _ in
                        self?.navigationController?.popViewController(animated: true)
                    })
                }
            })
        }
        
        let commonSuccessClosure = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loadingViewController.dismiss(animated: false) {
                ui.clearCodeTextFields()
                var statusText = String()
                switch strongSelf.model.actionType {
                case .changePin1:
                    statusText = L(.myEidCodeChangedSuccessMessage, [IdCardCodeName.PIN1.rawValue])
                    UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: statusText)
                case .changePin2:
                    statusText = L(.myEidCodeChangedSuccessMessage, [IdCardCodeName.PIN2.rawValue])
                    UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: statusText)
                case .unblockPin1:
                    statusText = L(.myEidCodeUnblockedSuccessMessage, [IdCardCodeName.PIN1.rawValue])
                    strongSelf.infoManager.retryCounts.pin1 = IdCardCodeLengthLimits.maxRetryCount.rawValue
                    UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: statusText)
                case .unblockPin2:
                    statusText = L(.myEidCodeUnblockedSuccessMessage, [IdCardCodeName.PIN2.rawValue])
                    strongSelf.infoManager.retryCounts.pin2 = IdCardCodeLengthLimits.maxRetryCount.rawValue
                    UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: statusText)
                case .changePuk:
                    statusText = L(.myEidCodeChangedSuccessMessage, [IdCardCodeName.PUK.rawValue])
                    UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: statusText)
                }
                ui.showStatusView(with: statusText)
            }
        }

        ui.clearInlineErrors()
        
        if let invalidCodesError = validateCodes() {
            if invalidCodesError.textFieldIndex == 0 {
                ui.firstInlineErrorLabel.isHidden = false
                ui.firstInlineErrorLabel.text = invalidCodesError.message
                ui.setViewBorder(view: ui.firstCodeTextField)
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: ui.firstInlineErrorLabel)
            }
            else if invalidCodesError.textFieldIndex == 1 || invalidCodesError.textFieldIndex == 2 {
                ui.secondInlineErrorLabel.isHidden = false
                ui.secondInlineErrorLabel.text = invalidCodesError.message
                ui.setViewBorder(view: ui.secondCodeTextField)
                ui.setViewBorder(view: ui.thirdCodeTextField)
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: ui.secondInlineErrorLabel)
            }
            return
        }

        let oldCode = ui.firstCodeTextField.text ?? String()
        let newCode = ui.secondCodeTextField.text ?? String()
        let pukCode = oldCode
        
        present(loadingViewController, animated: false) { [weak self] in
            guard let strongSelf = self else { return }
            switch strongSelf.model.actionType {
            case .changePin1:
                MoppLibPinActions.changePin1(to: newCode, withOldPin1: oldCode, success: {
                    commonSuccessClosure()
                }, failure: failureClosure)
                
            case .changePin2:
                MoppLibPinActions.changePin2(to: newCode, withOldPin2: oldCode, success: {
                    commonSuccessClosure()
                }, failure: failureClosure)
                
            case .unblockPin1:
                MoppLibPinActions.changePin1(to: newCode, withPuk: pukCode, success: {
                    commonSuccessClosure()
                }, failure: failureClosure)
                
            case .unblockPin2:
                MoppLibPinActions.changePin2(to: newCode, withPuk: pukCode, success: {
                    commonSuccessClosure()
                }, failure: failureClosure)
                
            case .changePuk:
                MoppLibPinActions.changePuk(to: newCode, withOldPuk: oldCode, success: {
                    commonSuccessClosure()
                }, failure: failureClosure)
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

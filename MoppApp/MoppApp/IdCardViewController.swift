//
//  IdCardSignViewController.swift
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

import SkSigningLib

protocol IdCardSignViewKeyboardDelegate : AnyObject {
    func idCardPINKeyboardWillAppear()
    func idCardPINKeyboardWillDisappear()
}

protocol IdCardDecryptViewControllerDelegate : AnyObject {
    func idCardDecryptDidFinished(success: Bool, dataFiles: [String:Data], error: Error?)
}

class IdCardViewController : MoppViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var idCardView: UIView!
    @IBOutlet weak var containerStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pinCodeStackView: UIStackView!
    @IBOutlet weak var pinTextField: UITextField!
    @IBOutlet weak var cancelButton: ScaledButton!
    @IBOutlet weak var actionButton: ScaledButton!
    @IBOutlet weak var pinTextFieldTitleLabel: UILabel!
    @IBOutlet weak var loadingSpinner: SpinnerView!

    var isActionDecryption = false
    var containerPath: String!
    var cardCommands: CardCommands?
    weak var decryptDelegate: IdCardDecryptViewControllerDelegate?
    weak var keyboardDelegate: IdCardSignViewKeyboardDelegate? = nil

    enum State {
        case initial
        case readerNotFound     // Reader not found/selected
        case readerRestarted    // Reader discovery restarting
        case idCardNotFound     // ID card not found
        case idCardConnected    // ID card found and connected
        case readerProcessFailed    // Failed to read data
        case readyForTokenAction    // Reader and ID card found
        case tokenActionInProcess            // Token action in-progress
        case wrongPin
    }

    var state: State = .initial {
        didSet {
            updateUI(for: state)
        }
    }

    var pinAttemptsLeft: UInt = 0
    var initialStateStartedTime: TimeInterval = 0
    var initialStateExpirationTimer: Timer? = nil
    var idCardPersonalData: MoppLibPersonalData? = nil

    var accessibilityObjects: [NSObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        MoppLibCardReaderManager.shared.delegate = self

        cancelButton.setTitle(L(.actionCancel).uppercased())
        cancelButton.accessibilityLabel = L(.actionCancel).lowercased()
        if isActionDecryption {
            actionButton.setTitle(L(.actionDecrypt).uppercased())
            actionButton.accessibilityLabel = L(.actionDecrypt).lowercased()
        } else {
            actionButton.setTitle(L(.actionSign).uppercased())
            actionButton.accessibilityLabel = L(.actionSign).lowercased()
        }
        
        cancelButton.adjustedFont()
        actionButton.adjustedFont()

        pinTextField.delegate = self
        pinTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        pinTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        pinTextField.layer.borderWidth = 1.0
        pinTextField.moppPresentDismissButton()

        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: titleLabel)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if pinTextField != nil {
            pinTextField.removeTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        }
    }

    @objc func editingChanged(sender: UITextField) {
        let count = (sender.text?.count ?? 0)
        if self.isActionDecryption {
            actionButton.isEnabled = count >= 4 && count <= 12
        } else {
            actionButton.isEnabled = count >= 5 && count <= 12
        }
        if !actionButton.isEnabled {
            actionButton.backgroundColor = UIColor.moppBackgroundDark
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI(for: .initial)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateUI(for: state)

        if UIAccessibility.isVoiceOverRunning {
            guard let titleUILabel = titleLabel, let pinTextFieldUITitleLabel = pinTextFieldTitleLabel, let pinTextUIField = pinTextField, let cancelUIButton = cancelButton, let actionUIButton = actionButton else {
                printLog("Unable to get titleLabel, pinTextFieldTitleLabel, pinTextField, cancelButton or actionButton")
                return
            }
            
            self.view.accessibilityElements = [titleUILabel, pinTextFieldUITitleLabel, pinTextUIField, cancelUIButton, actionUIButton]
            
            accessibilityObjects = [titleLabel, pinTextFieldTitleLabel, pinTextField, cancelButton, actionButton]
            
            self.view.accessibilityElements = accessibilityObjects
            accessibilityElements = accessibilityObjects
        }

        // Application did become active
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: OperationQueue.main) { [weak self]_ in
            guard let sself = self else { return }
            let showLoading =
                sself.state == .initial ||
                sself.state == .readerNotFound ||
                sself.state == .idCardNotFound ||
                sself.state == .tokenActionInProcess
                self?.loadingSpinner?.show(showLoading)
                if self?.pinTextField != nil {
                    self?.pinTextField.resignFirstResponder()
                }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self]_ in
            self?.loadingSpinner?.show(true)
            UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: self?.titleLabel)
        }

        // Application will resign active
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: OperationQueue.main) {_ in
            UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: self.titleLabel)
        }
        // PIN2 keyboard will appear
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main) { [weak self]_ in
            self?.keyboardDelegate?.idCardPINKeyboardWillAppear()
        }
        // PIN2 keyboard will disappear
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main) { [weak self]_ in
            self?.keyboardDelegate?.idCardPINKeyboardWillDisappear()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboardAccessibility), name: .focusedAccessibilityElement, object: nil)

        MoppLibCardReaderManager.shared.startDiscoveringReaders()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        MoppLibCardReaderManager.shared.stopDiscoveringReaders()
        NotificationCenter.default.removeObserver(self)
    }

    @objc func changeState() {
        state = .readyForTokenAction
    }

    func updateUI(for state: State) {
        scrollView.setContentOffset(.zero, animated: true)
        actionButton.isEnabled = false
        pinTextField.isHidden = true
        pinTextField.text = nil
        pinTextFieldTitleLabel.isHidden = true
        pinTextFieldTitleLabel.text = nil
        pinTextFieldTitleLabel.textColor = UIColor.moppBaseBackground
        loadingSpinner?.show(true)
        pinCodeStackView?.isHidden = false
        switch state {
        case .initial:
            titleLabel.text = L(.cardReaderStateInitial)
        case .readerNotFound:
            UIAccessibility.post(notification: .announcement,  argument: L(.cardReaderStateReaderNotFound))
            titleLabel.text = L(.cardReaderStateReaderNotFound)
            pinCodeStackView?.isHidden = true
        case .readerProcessFailed:
            UIAccessibility.post(notification: .announcement, argument: L(.cardReaderStateReaderProcessFailed))
            titleLabel.text = L(.cardReaderStateReaderProcessFailed)
            pinCodeStackView?.isHidden = true
        case .readerRestarted:
            UIAccessibility.post(notification: .announcement,  argument: L(.cardReaderStateReaderRestarted))
            titleLabel.text = L(.cardReaderStateReaderRestarted)
        case .idCardNotFound:
            UIAccessibility.post(notification: .announcement, argument: L(.cardReaderStateIdCardNotFound))
            titleLabel.text = L(.cardReaderStateIdCardNotFound)
        case .idCardConnected:
            UIAccessibility.post(notification: .announcement, argument: L(.cardReaderStateIdCardConnected))
            titleLabel.text = L(.cardReaderStateIdCardConnected)
        case .tokenActionInProcess:
            UIAccessibility.post(notification: .announcement, argument: isActionDecryption ? L(.decryptionInProgress) : L(.signingInProgress))
        case .readyForTokenAction:
            // Give VoiceOver time to announce "ID-card found"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                let fullname = self.idCardPersonalData?.fullName ?? String()
                let personalCode = self.idCardPersonalData?.personalIdentificationCode ?? String()
                if self.isActionDecryption {
                    self.titleLabel.text = L(.cardReaderStateReadyForPin1, [fullname, personalCode])
                    UIAccessibility.post(notification: .announcement, argument: L(.cardReaderStateReadyForPin1, [fullname, personalCode]))
                } else {
                    self.titleLabel.text = L(.cardReaderStateReadyForPin2, [fullname, personalCode])
                    UIAccessibility.post(notification: .announcement, argument: L(.cardReaderStateReadyForPin2, [fullname, personalCode]))
                }
                self.loadingSpinner?.show(false)
                self.pinTextField.isHidden = false
                self.pinTextFieldTitleLabel.isHidden = false
                self.pinTextFieldTitleLabel.text = self.isActionDecryption ? L(.pin1TextfieldLabel) : L(.pin2TextfieldLabel)
                self.pinTextFieldTitleLabel.textColor = UIColor.moppText
                // Voice Control label might not show, showing and hiding the textfield helps
                if !UIAccessibility.isVoiceOverRunning {
                    self.pinTextField.becomeFirstResponder()
                    self.pinTextField.resignFirstResponder()
                    self.pinTextField.layer.borderColor = UIColor.black.cgColor
                }
                self.setPinFieldVoiceControlLabel(isDecryption: self.isActionDecryption)
            }
        case .wrongPin:
            let fullname = idCardPersonalData?.fullName ?? String()
            let personalCode = idCardPersonalData?.personalIdentificationCode ?? String()
            if isActionDecryption {
                titleLabel.text = L(.cardReaderStateReadyForPin1, [fullname, personalCode])
                UIAccessibility.post(notification: .layoutChanged, argument: titleLabel)
            } else {
                titleLabel.text = L(.cardReaderStateReadyForPin2, [fullname, personalCode])
                UIAccessibility.post(notification: .layoutChanged, argument: titleLabel)
            }
            loadingSpinner?.show(false)
            pinTextField.isHidden = false
            pinTextFieldTitleLabel.isHidden = false
            pinTextFieldTitleLabel.textColor = UIColor.moppError
            if isActionDecryption {
                pinTextFieldTitleLabel.text = pinAttemptsLeft > 1 ? L(.wrongPin1, [pinAttemptsLeft]) : L(.wrongPin1Single)
                UIAccessibility.post(notification: .layoutChanged, argument: pinTextFieldTitleLabel)
            } else {
                pinTextFieldTitleLabel.text = pinAttemptsLeft > 1 ? L(.wrongPin2, [pinAttemptsLeft]) : L(.wrongPin2Single)
                UIAccessibility.post(notification: .layoutChanged, argument: pinTextFieldTitleLabel)
            }
        }

        guard let actionUIButton = actionButton else { printLog("Unable to get actionButton"); return }
        actionUIButton.backgroundColor = UIColor.moppBackgroundDark

        if state == .initial {
            initialStateExpirationTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: false, block: { [weak self]_ in
                DispatchQueue.main.async {
                    self?.state = .readerNotFound
                }
            })
        } else {
            initialStateExpirationTimer?.invalidate()
            initialStateExpirationTimer = nil
        }

        DispatchQueue.main.async {
            self.view.layoutIfNeeded()

            for subview in self.view.subviews {
                if subview.isKind(of: UIView.self) {
                    self.view.isAccessibilityElement = false
                    guard let titleUILabel = self.titleLabel, let pinUITextFieldTitleLabel = self.pinTextFieldTitleLabel, let pinUITextField = self.pinTextField, let cancelUIButton = self.cancelButton, let actionUIButton = self.actionButton else {
                        return
                    }
                    subview.accessibilityElements = [titleUILabel, pinUITextFieldTitleLabel, pinUITextField, cancelUIButton, actionUIButton]
                }
            }
            self.setPinFieldVoiceControlLabel(isDecryption: self.isActionDecryption)
        }
        self.setPinFieldVoiceControlLabel(isDecryption: self.isActionDecryption)
    }
    
    private func setPinFieldVoiceControlLabel(isDecryption: Bool) {
        if !UIAccessibility.isVoiceOverRunning {
            if isDecryption {
                self.pinTextField.accessibilityLabel = "\(L(.voiceControlPin1Field))"
                self.pinTextField.accessibilityUserInputLabels = [L(.voiceControlPin1Field)]
            } else {
                self.pinTextField.accessibilityLabel = "\(L(.voiceControlPin2Field))"
                self.pinTextField.accessibilityUserInputLabels = [L(.voiceControlPin2Field)]
            }
        }
    }

    @IBAction func cancelAction() {
        let actionCancelled = state == .tokenActionInProcess
        dismiss(animated: false) {
            [weak self] in
            guard let sself = self else { return }
            if actionCancelled {
                ErrorUtil.generateError(signingError: L(.signingAbortedMessage))
            }
            if sself.isActionDecryption {
                UIAccessibility.post(notification: .screenChanged, argument: L(.cryptoDecryptionCancelled))
            } else {
                UIAccessibility.post(notification: .screenChanged, argument: L(.signingCancelled))
            }
        }
    }

    @IBAction func tokenAction() {
        guard let pin = pinTextField.text else {
            // TODO: Display error message about empty PIN 2 text field
            return
        }

        state = .tokenActionInProcess
        if isActionDecryption {
            guard let cardCommands else {
                decryptDelegate?.idCardDecryptDidFinished(success: false, dataFiles: .init(), error: MoppLibError.Code.cardNotFound)
                return
            }
            MoppLibCryptoActions.decryptData(
                containerPath, with: SmartToken(card: cardCommands, pin1: pin),
                success: { [weak self] decryptedData in
                    self?.decryptDelegate?.idCardDecryptDidFinished(success: true, dataFiles: decryptedData, error: nil)
                },
                failure: { [weak self] error in
                    if let nsError = error as NSError?,
                       nsError == .wrongPin {
                        DispatchQueue.main.async {
                            self?.pinAttemptsLeft = (nsError.userInfo[MoppLibError.kMoppLibUserInfoRetryCount] as? NSNumber)?.uintValue ?? 0
                            self?.state = .wrongPin
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.dismiss(animated: false) {
                                self?.decryptDelegate?.idCardDecryptDidFinished(success: false, dataFiles: .init(), error: error)
                            }
                        }
                    }
                }
            )
        } else if DefaultsHelper.isRoleAndAddressEnabled {
            let roleAndAddressView = UIStoryboard.tokenFlow.instantiateViewController(of: RoleAndAddressViewController.self)
            roleAndAddressView.modalPresentationStyle = .overCurrentContext
            roleAndAddressView.modalTransitionStyle = .crossDissolve
            roleAndAddressView.onComplete = { [weak self] in self?.sign(pin) }
            present(roleAndAddressView, animated: true)
        } else {
            sign(pin)
        }
    }

    func sign(_ pin: String) {
        Task {
            do {
                guard MoppLibManager.shared.isConnected else {
                    throw MoppLibError.Code.noInternetConnection
                }
                guard let cardCommands else {
                    throw MoppLibError.Code.cardNotFound
                }
                guard try await cardCommands.readCodeCounterRecord(.pin2) != 0 else {
                    throw MoppLibError.Code.pinBlocked
                }
                let cert = try await cardCommands.readSignatureCertificate()
                let dataToSign = try MoppLibContainerActions.prepareSignature(
                    cert,
                    containerPath: containerPath,
                    roleData: DefaultsHelper.isRoleAndAddressEnabled ? RoleAndAddressUtil.getSavedRoleInfo() : nil,
                    isNFCSignature: false
                )
                let signature = try cardCommands.calculateSignature(for: dataToSign, withPin2: pin)
                try MoppLibContainerActions.isSignatureValid(signature)
                await MainActor.run {
                    self.dismiss(animated: false) {
                        NotificationCenter.default.post(
                            name: .signatureCreatedFinishedNotificationName,
                            object: nil,
                            userInfo: nil)
                    }
                }
            } catch let error as NSError {
                await MainActor.run {
                    if error == .wrongPin {
                        self.pinAttemptsLeft = (error.userInfo[MoppLibError.kMoppLibUserInfoRetryCount] as? NSNumber)?.uintValue ?? 0
                        self.state = .wrongPin
                    } else {
                        self.dismiss(animated: false) {
                            ErrorUtil.generateError(signingError: error, signingType:SigningType.idCard)
                        }
                    }
                }
            }
        }
    }
    
    @objc func hideKeyboardAccessibility(notification: Notification) {
        if let view = notification.userInfo?["view"] as? UIView {
            if view.accessibilityIdentifier == "IdCardCancelButton" || view.accessibilityIdentifier == "IdCardActionButton" {
                self.view.endEditing(true)
                hideKeyboard(scrollView: scrollView)
            }
        }
    }
    
    override func keyboardWillShow(notification: NSNotification) {
        if pinTextField.isFirstResponder {
            showKeyboard(textFieldLabel: pinTextFieldTitleLabel, scrollView: scrollView)
        }
    }
    
    override func keyboardWillHide(notification: NSNotification) {
        hideKeyboard(scrollView: scrollView)
    }
}

extension IdCardViewController : MoppLibCardReaderManagerDelegate {
    func moppLibCardReaderStatusDidChange(_ readerStatus: MoppLibCardReaderStatus) {
        cardCommands = nil
        switch readerStatus {
        case .Initial: state = .initial
        case .ReaderNotConnected: state = .readerNotFound
        case .ReaderRestarted: state = .readerRestarted
        case .ReaderConnected: state = .idCardNotFound
        case .CardConnected(let cardCommands):
            state = .idCardConnected
            self.cardCommands = cardCommands

            Task.detached { [weak self] in
                do {
                    let moppLibPersonalData = try await cardCommands.readPublicData()
                    guard let self else { return }
                    await MainActor.run {
                        self.idCardPersonalData = moppLibPersonalData
                        self.state = .readyForTokenAction
                    }
                } catch let error as NSError {
                    await MainActor.run { [weak self] in
                        self?.state = error == .readerProcessFailed ? .readerProcessFailed : .readerNotFound
                    }
                } catch {
                    await MainActor.run { [weak self] in self?.state = .readerProcessFailed }
                }
            }

        case .ReaderProcessFailed: state = .readerProcessFailed
        }
    }
    
    func verifySigningCapability() {
        let pinTextField = pinTextField.text ?? String()
        actionButton.isEnabled = !TokenFlowUtil.isPinCodeValid(text: pinTextField, pinType: .PIN2)
        actionButton.backgroundColor = actionButton.isEnabled ? UIColor.moppBase : UIColor.moppLabel
    }
}

extension IdCardViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.count == 0 {
            actionButton.backgroundColor = UIColor.moppBackgroundDark
            return true
        }
        let text = (textField.text ?? String()) + string
        return text.isNumeric && text.count <= 12
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.accessibilityIdentifier == "idCardPinCodeField" && textField.hasText {
            if let text = textField.text as String? {
                if self.isActionDecryption {
                    verifyPinCodeValidity(textField: textField, textFieldTitle: pinTextFieldTitleLabel, text: text, defaultLabelText: L(.pin1TextfieldLabel), errorText: L(.signingErrorIncorrectPinLength, [IdCardCodeName.PIN1.rawValue, IdCardCodeLengthLimits.pin1Minimum.rawValue]), pinType: .PIN1)
                } else {
                    verifyPinCodeValidity(textField: textField, textFieldTitle: pinTextFieldTitleLabel, text: text, defaultLabelText: L(.pin2TextfieldLabel), errorText: L(.signingErrorIncorrectPinLength, [IdCardCodeName.PIN2.rawValue, IdCardCodeLengthLimits.pin2Minimum.rawValue]), pinType: .PIN2)
                }
            }
        }
    }
    
    func verifyPinCodeValidity(textField: UITextField, textFieldTitle: UILabel, text: String, defaultLabelText: String, errorText: String, pinType: IdCardCodeName) {
        if !TokenFlowUtil.isPinCodeValid(text: text, pinType: pinType) {
            setTextFieldError(textField: textField, textFieldTitle: textFieldTitle, text: errorText)
            setViewBorder(view: textField, color: .moppError)
            UIAccessibility.post(notification: .screenChanged, argument: textFieldTitle)
        } else {
            removeViewBorder(view: textField)
            resetTextField(textField: pinTextField, textFieldTitle: textFieldTitle, text: defaultLabelText)
            UIAccessibility.post(notification: .screenChanged, argument: textField)
        }
    }
    
    func setTextFieldError(textField: UITextField, textFieldTitle: UILabel, text: String) {
        textFieldTitle.text = text
        textFieldTitle.textColor = .moppError
    }
    
    func resetTextField(textField: UITextField, textFieldTitle: UILabel, text: String) {
        textFieldTitle.text = text
        textFieldTitle.textColor = .black
    }
}

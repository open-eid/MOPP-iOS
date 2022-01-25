//
//  IdCardSignViewController.swift
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
enum IdCardActionError: Error {
    case actionCancelled
}

protocol IdCardSignViewKeyboardDelegate : AnyObject {
    func idCardPINKeyboardWillAppear()
    func idCardPINKeyboardWillDisappear()
}

protocol IdCardSignViewControllerDelegate : AnyObject {
    func idCardSignDidFinished(cancelled: Bool, success: Bool, error: Error?)
}

protocol IdCardDecryptViewControllerDelegate : AnyObject {
    func idCardDecryptDidFinished(cancelled: Bool, success: Bool, dataFiles: NSMutableDictionary, error: Error?)
}

class IdCardViewController : MoppViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pinTextField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var pinTextFieldTitleLabel: UILabel!
    @IBOutlet weak var loadingSpinner: SpinnerView!
    @IBOutlet weak var titleLabelBottomToCancelButtonCSTR: NSLayoutConstraint!
    @IBOutlet weak var titleLabelBottomToPin2TextFieldCSTR: NSLayoutConstraint!
    var isActionDecryption = false
    var containerPath: String!
    weak var signDelegate: IdCardSignViewControllerDelegate?
    weak var decryptDelegate: IdCardDecryptViewControllerDelegate?
    weak var keyboardDelegate: IdCardSignViewKeyboardDelegate? = nil

    enum State {
        case initial
        case readerNotFound     // Reader not found/selected
        case idCardNotFound     // ID card not found
        case idCardConnected    // ID card found and connected
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

        MoppLibCardReaderManager.sharedInstance().delegate = self

        cancelButton.setTitle(L(.actionCancel).uppercased())
        if isActionDecryption {
            actionButton.setTitle(L(.actionDecrypt).uppercased())
        } else {
            actionButton.setTitle(L(.actionSign).uppercased())
        }


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
        actionButton.isEnabled = count >= 4 && count <= 6
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

        guard let titleUILabel = titleLabel, let pinTextFieldUITitleLabel = pinTextFieldTitleLabel, let pinTextUIField = pinTextField, let cancelUIButton = cancelButton, let actionUIButton = actionButton else {
            NSLog("Unable to get titleLabel, pinTextFieldTitleLabel, pinTextField, cancelButton or actionButton")
            return
        }

        self.view.accessibilityElements = [titleUILabel, pinTextFieldUITitleLabel, pinTextUIField, cancelUIButton, actionUIButton]

        accessibilityObjects = [titleLabel, pinTextFieldTitleLabel, pinTextField, cancelButton, actionButton]

        self.view.accessibilityElements = accessibilityObjects
        accessibilityElements = accessibilityObjects

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
            self?.loadingSpinner.show(showLoading)
            self?.pinTextField.resignFirstResponder()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self]_ in
            self?.loadingSpinner.show(true)
            UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: self?.titleLabel)
        }

        // Application will resign active
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: OperationQueue.main) {_ in
            MoppLibCardReaderManager.sharedInstance().stopDiscoveringReaders()
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

        MoppLibCardReaderManager.sharedInstance().delegate = self
        MoppLibCardReaderManager.sharedInstance().startDiscoveringReaders()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        MoppLibCardReaderManager.sharedInstance().delegate = nil
        MoppLibCardReaderManager.sharedInstance().stopDiscoveringReaders()
        NotificationCenter.default.removeObserver(self)
    }

    @objc func changeState() {
        state = .readyForTokenAction
    }

    func updateUI(for state: State) {
        if isNonDefaultPreferredContentSizeCategory() {
            titleLabel.font = UIFont.setCustomFont(font: .regular, nil, .body)
        }
        switch state {
        case .initial:
            actionButton.isEnabled = false
            pinTextField.isHidden = true
            pinTextField.text = nil
            pinTextFieldTitleLabel.isHidden = true
            pinTextFieldTitleLabel.text = nil
            pinTextFieldTitleLabel.textColor = UIColor.moppBaseBackground
            loadingSpinner.show(true)
            titleLabel.text = L(.cardReaderStateInitial)
        case .readerNotFound:
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement,  argument: L(.cardReaderStateReaderNotFound))
            actionButton.isEnabled = false
            pinTextField.isHidden = true
            pinTextField.text = nil
            pinTextFieldTitleLabel.isHidden = true
            pinTextFieldTitleLabel.text = nil
            pinTextFieldTitleLabel.textColor = UIColor.moppBaseBackground
            loadingSpinner.show(true)
            titleLabel.text = L(.cardReaderStateReaderNotFound)
        case .idCardNotFound:
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: L(.cardReaderStateIdCardNotFound))
            actionButton.isEnabled = false
            pinTextField.isHidden = true
            pinTextField.text = nil
            pinTextFieldTitleLabel.isHidden = true
            pinTextFieldTitleLabel.text = nil
            pinTextFieldTitleLabel.textColor = UIColor.moppBaseBackground
            loadingSpinner.show(true)
            titleLabel.text = L(.cardReaderStateIdCardNotFound)
        case .idCardConnected:
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: L(.cardReaderStateIdCardConnected))
            actionButton.isEnabled = false
            pinTextField.isHidden = true
            pinTextField.text = nil
            pinTextFieldTitleLabel.isHidden = true
            pinTextFieldTitleLabel.text = nil
            pinTextFieldTitleLabel.textColor = UIColor.moppBaseBackground
            loadingSpinner.show(true)
            titleLabel.text = L(.cardReaderStateIdCardConnected)
        case .readyForTokenAction:
            // Give VoiceOver time to announce "ID-card found"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                let fullname = self.idCardPersonalData?.fullName() ?? String()
                let personalCode = self.idCardPersonalData?.personalIdentificationCode ?? String()
                if self.isActionDecryption {
                    self.titleLabel.text = L(.cardReaderStateReadyForPin1, [fullname, personalCode])
                    UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: L(.cardReaderStateReadyForPin1, [fullname, personalCode]))
                } else {
                    self.titleLabel.text = L(.cardReaderStateReadyForPin2, [fullname, personalCode])
                    UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: L(.cardReaderStateReadyForPin2, [fullname, personalCode]))
                }
                self.actionButton.isEnabled = false
                self.pinTextField.isHidden = false
                self.pinTextField.text = nil
                self.pinTextFieldTitleLabel.isHidden = false
                if self.isActionDecryption {
                    self.pinTextFieldTitleLabel.text = L(.pin1TextfieldLabel)
                } else {
                    self.pinTextFieldTitleLabel.text = L(.pin2TextfieldLabel)
                }
                self.pinTextFieldTitleLabel.textColor = UIColor.moppText
                self.loadingSpinner.show(false)
            }
        case .tokenActionInProcess:
            actionButton.isEnabled = false
            pinTextField.isHidden = true
            pinTextField.text = nil
            pinTextFieldTitleLabel.isHidden = true
            pinTextFieldTitleLabel.text = nil
            pinTextFieldTitleLabel.textColor = UIColor.moppBaseBackground
            loadingSpinner.show(true)
            if isActionDecryption {
                titleLabel.text = L(.decryptionInProgress)
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: titleLabel)
            } else {
                titleLabel.text = L(.signingInProgress)
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: titleLabel)
            }
        case .wrongPin:
            let fullname = idCardPersonalData?.fullName() ?? String()
            let personalCode = idCardPersonalData?.personalIdentificationCode ?? String()
            if isActionDecryption {
                titleLabel.text = L(.cardReaderStateReadyForPin1, [fullname, personalCode])
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: titleLabel)
            } else {
                titleLabel.text = L(.cardReaderStateReadyForPin2, [fullname, personalCode])
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: titleLabel)
            }
            actionButton.isEnabled = false
            pinTextField.isHidden = false
            pinTextField.text = nil
            pinTextFieldTitleLabel.isHidden = false
            pinTextField.text = nil
            loadingSpinner.show(false)
            pinTextFieldTitleLabel.textColor = UIColor.moppError
            if isActionDecryption {
                pinTextFieldTitleLabel.text = pinAttemptsLeft > 1 ? L(.wrongPin1, [pinAttemptsLeft]) : L(.wrongPin1Single)
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: pinTextFieldTitleLabel)
            } else {
                pinTextFieldTitleLabel.text = pinAttemptsLeft > 1 ? L(.wrongPin2, [pinAttemptsLeft]) : L(.wrongPin2Single)
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: pinTextFieldTitleLabel)
            }

        }

        guard let actionUIButton = actionButton else { NSLog("Unable to get actionButton"); return }
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

        view.layoutIfNeeded()

        for subview in self.view.subviews {
            if subview.isKind(of: UIView.self) {
                self.view.isAccessibilityElement = false
                guard let titleUILabel = titleLabel, let pinUITextFieldTitleLabel = pinTextFieldTitleLabel, let pinUITextField = pinTextField, let cancelUIButton = cancelButton, let actionUIButton = actionButton else {
                    return
                }
                subview.accessibilityElements = [titleUILabel, pinUITextFieldTitleLabel, pinUITextField, cancelUIButton, actionUIButton]
            }
        }


    }

    @IBAction func cancelAction() {
        let actionCancelled = state == .tokenActionInProcess
        dismiss(animated: false) {
            [weak self] in
            guard let sself = self else { return }
            var error: IdCardActionError? = nil
            if actionCancelled {
                error = .actionCancelled
            }
            sself.signDelegate?.idCardSignDidFinished(cancelled: true, success: false, error: error)
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
            MoppLibCryptoActions.sharedInstance().decryptData(containerPath, withPin1: pin,
                success: {(_ decryptedData: NSMutableDictionary?) -> Void in
                    guard let strongDecryptedData = decryptedData else { return }
                    self.decryptDelegate?.idCardDecryptDidFinished(cancelled: false, success: true,  dataFiles: strongDecryptedData, error: nil)
            },
                failure: { [weak self] error in
                    guard let nsError = error as NSError? else { return }
                    if nsError.code == Int(MoppLibErrorCode.moppLibErrorWrongPin.rawValue) { // Wrong PIN1 error
                        DispatchQueue.main.async {
                            self?.pinAttemptsLeft = (nsError.userInfo[kMoppLibUserInfoRetryCount] as? NSNumber)?.uintValue ?? 0
                            self?.state = .wrongPin
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.dismiss(animated: false, completion: {
                                self?.decryptDelegate?.idCardDecryptDidFinished(cancelled: false, success: false, dataFiles: NSMutableDictionary(), error: error)
                            })
                        }
                    }
                }
            )

        } else {
            MoppLibContainerActions.sharedInstance().addSignature(containerPath, withPin2:pin, success: { [weak self] container, signatureAdded in
                DispatchQueue.main.async {
                    self?.dismiss(animated: false, completion: {
                        self?.signDelegate?.idCardSignDidFinished(cancelled: false, success: signatureAdded, error: nil)
                    })
                }
            }, failure: { [weak self] error in
                guard let nsError = error as NSError? else { return }
                if nsError.code == Int(MoppLibErrorCode.moppLibErrorWrongPin.rawValue) { // Wrong PIN2 error
                    DispatchQueue.main.async {
                        self?.pinAttemptsLeft = (nsError.userInfo[kMoppLibUserInfoRetryCount] as? NSNumber)?.uintValue ?? 0
                        self?.state = .wrongPin
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.dismiss(animated: false, completion: {
                            self?.signDelegate?.idCardSignDidFinished(cancelled: false, success: false, error: nsError)
                        })
                    }
                }
            })

        }

    }
}

extension IdCardViewController : MoppLibCardReaderManagerDelegate {
    func moppLibCardReaderStatusDidChange(_ readerStatus: MoppLibCardReaderStatus) {
        switch readerStatus {
        case .ReaderNotConnected:
            state = .readerNotFound
        case .ReaderConnected:
            state = .idCardNotFound
        case .CardConnected:
            state = .idCardConnected

            // Give some time for UI to update before executing data requests
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
                guard let strongSelf = self else { return }
                MoppLibCardActions.minimalCardPersonalData(success: { [weak self] moppLibPersonalData in
                    DispatchQueue.main.async {
                        self?.idCardPersonalData = moppLibPersonalData
                        self?.state = .readyForTokenAction
                    }
                }, failure: { [weak self]_ in
                    strongSelf.state = .readerNotFound
                })
            })

        @unknown default:
            break
        }
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
}

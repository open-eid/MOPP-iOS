//
//  ProxyViewController.swift
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

import UIKit
import SkSigningLib

enum ProxyNetworkError: Error {
    case invalidURL
    case noConnection
    case checkUsernameAndPassword
}

class ProxyViewController: MoppViewController, URLSessionDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var proxyTitle: ScaledLabel!
    @IBOutlet weak var dismissButton: ScaledButton!
    
    @IBOutlet weak var useNoProxyStackView: UIStackView!
    @IBOutlet weak var useSystemProxyStackView: UIStackView!
    @IBOutlet weak var useManualProxyStackView: UIStackView!
    
    @IBOutlet weak var useNoProxyView: UIView!
    @IBOutlet weak var useSystemProxyView: UIView!
    @IBOutlet weak var useManualProxyView: UIView!
    
    @IBOutlet weak var useNoProxyRadioButton: RadioButton!
    @IBOutlet weak var useSystemProxyRadioButton: RadioButton!
    @IBOutlet weak var useManualProxyRadioButton: RadioButton!
    
    @IBOutlet weak var useNoProxyLabel: ScaledLabel!
    @IBOutlet weak var useSystemProxyLabel: ScaledLabel!
    @IBOutlet weak var useManualProxyLabel: ScaledLabel!
    
    @IBOutlet weak var hostLabel: ScaledLabel!
    @IBOutlet weak var hostTextField: SettingsTextField!
    
    @IBOutlet weak var portLabel: ScaledLabel!
    @IBOutlet weak var portTextField: SettingsTextField!
    @IBOutlet weak var portErrorLabel: ScaledLabel!
    
    @IBOutlet weak var usernameLabel: ScaledLabel!
    @IBOutlet weak var usernameTextField: SettingsTextField!
    
    @IBOutlet weak var passwordLabel: ScaledLabel!
    @IBOutlet weak var passwordTextField: SettingsTextField!
    
    @IBOutlet weak var checkConnectionView: UIView!
    @IBOutlet weak var checkConnectionButton: ScaledLabel!    
    
    @IBAction func dismissView(_ sender: ScaledButton) {
        dismiss(animated: true)
    }
    
    var currentlyEditingCell: IndexPath?
    var currentlyEditingField: UITextField?
    
    enum Section {
        case header
        case fields
    }
    
    enum FieldId {
        case proxy
    }
    
    var sections:[Section] = [.header, .fields]
    
    var fields: [FieldId] = [
        .proxy
    ]
    
    var tapGR: UITapGestureRecognizer!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .gray.withAlphaComponent(0.5)
    }
    
    override func keyboardWillHide(notification: NSNotification) {
        hideKeyboard(scrollView: scrollView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hostTextField.delegate = self
        portTextField.delegate = self
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        dismissButton.setTitle(L(.closeButton))
        
        useNoProxyLabel.text = L(.settingsProxyNoProxy)
        useSystemProxyLabel.text = L(.settingsProxyUseSystem)
        useManualProxyLabel.text = L(.settingsProxyUseManual)
        
        presentDismissButton(hostTextField)
        presentDismissButton(portTextField)
        presentDismissButton(usernameTextField)
        presentDismissButton(passwordTextField)
        
        setBorder(hostTextField)
        setBorder(portTextField)
        setBorder(usernameTextField)
        setBorder(passwordTextField)
        
        hostTextField.isAccessibilityElement = true
        portTextField.isAccessibilityElement = true
        usernameTextField.isAccessibilityElement = true
        passwordTextField.isAccessibilityElement = true
        
        hostTextField.accessibilityLabel = L(.settingsProxyHost)
        portTextField.accessibilityLabel = L(.settingsProxyPort)
        usernameTextField.accessibilityLabel = L(.settingsProxyUsername)
        passwordTextField.accessibilityLabel = L(.settingsProxyPassword)
        
        hostTextField.accessibilityUserInputLabels = [L(.voiceControlProxyHost)]
        portTextField.accessibilityUserInputLabels = [L(.voiceControlProxyPort)]
        usernameTextField.accessibilityUserInputLabels = [L(.voiceControlProxyUsername)]
        passwordTextField.accessibilityUserInputLabels = [L(.voiceControlProxyPassword)]
        
        useNoProxyView.accessibilityUserInputLabels = [L(.voiceControlProxyNoProxy)]
        useSystemProxyView.accessibilityUserInputLabels = [L(.voiceControlProxySystemProxy)]
        useManualProxyView.accessibilityUserInputLabels = [L(.voiceControlProxyManualProxy)]
        
        if !(self.checkConnectionButton.gestureRecognizers?.contains(where: { $0 is UITapGestureRecognizer }) ?? false) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleProxyCheckTap(_:)))
            self.checkConnectionButton.addGestureRecognizer(tapGesture)
            self.checkConnectionButton.isUserInteractionEnabled = true
        }
        
        checkConnectionButton.text = L(.settingsProxyCheckConnectionButton)
        checkConnectionButton.textColor = UIColor.link
        checkConnectionButton.accessibilityLabel = L(.settingsProxyCheckConnectionButton).lowercased()
        checkConnectionButton.isUserInteractionEnabled = true
        checkConnectionButton.resetLabelProperties()
        
        self.checkConnectionView.accessibilityUserInputLabels = [L(.settingsProxyCheckConnectionButton)]
        
        guard let dismissButton = dismissButton, let proxyUITitle = proxyTitle, let noProxyUIView = useNoProxyStackView, let systemProxyUIView = useSystemProxyStackView, let manualProxyUIView = useManualProxyStackView, let hostUITextField: UITextField = hostTextField, let portUITextField = portTextField, let usernameUITextField = usernameTextField, let passwordUITextField = passwordTextField, let checkProxyConnectionUIButton = checkConnectionButton else {
            printLog("Unable to get proxyTitle, useNoProxyView, useSystemProxyView, useManualProxyView, hostTextField, portTextField, usernameTextField, passwordTextField, checkConnectionButton")
            return
        }
        
        if UIAccessibility.isVoiceOverRunning {
            self.accessibilityElements = [proxyUITitle, dismissButton, noProxyUIView, systemProxyUIView, manualProxyUIView, hostUITextField, portUITextField, usernameUITextField, passwordUITextField, checkProxyConnectionUIButton]
        }
        
        updateUI()
    }
    
    @objc func handleProxyCheckTap(_ sender: UITapGestureRecognizer) {
        checkProxyConnection { proxyError in
            var message: String?
            switch proxyError {
            case .noConnection, .invalidURL:
                    message = L(.settingsProxyCheckConnectionUnsuccessfulMessage)
                case .checkUsernameAndPassword:
                    message = L(.settingsProxyCheckConnectionCheckUsernameAndPassword)
                case .none:
                    message = L(.settingsProxyCheckConnectionSuccessMessage)
                }

            DispatchQueue.main.async {
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    func checkProxyConnection(completionHandler: @escaping (ProxyNetworkError?) -> Void) {
        saveProxySettings()
        
        guard let url = URL(string: "https://id.eesti.ee/config.json") else { completionHandler(ProxyNetworkError.invalidURL)
            return
        }
        
        let manualProxyConf = ManualProxy.getManualProxyConfiguration()
        
        let userAgent = MoppLibManager.sharedInstance().userAgent()
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        var urlSessionConfiguration: URLSessionConfiguration
        let urlSession: URLSession
        
        ProxySettingsUtil.updateSystemProxySettings()
        
        urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.timeoutIntervalForResource = 5.0
        urlSessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        ProxyUtil.configureURLSessionWithProxy(urlSessionConfiguration: &urlSessionConfiguration, manualProxyConf: manualProxyConf)
        ProxyUtil.setProxyAuthorizationHeader(request: &request, urlSessionConfiguration: urlSessionConfiguration, manualProxyConf: manualProxyConf)
        urlSession = URLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: nil)

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            
            if let _ = error as? NSError {
                completionHandler(ProxyNetworkError.noConnection)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                printLog("Proxy - Check connection. Unable to check if connection exists")
                completionHandler(ProxyNetworkError.noConnection)
                return
            }
            
            if httpResponse.statusCode == 403 {
                completionHandler(ProxyNetworkError.checkUsernameAndPassword)
                return
            } else if !(200...299).contains(httpResponse.statusCode) {
                completionHandler(ProxyNetworkError.noConnection)
                return
            }
            
            return completionHandler(nil)
        })

        task.resume()
    }
    
    func setAccessibilityElementsInStackView(stackView: UIStackView, isAccessibilityElement: Bool) {
        for subview in stackView.arrangedSubviews {
            subview.isAccessibilityElement = isAccessibilityElement
        }
    }
    
    
    func handleProxySetting(proxySetting: ProxySetting) {
        switch proxySetting {
        case .noProxy:
            self.useNoProxyRadioButton.setSelectedState(state: true)
            self.useSystemProxyRadioButton.setSelectedState(state: false)
            self.useManualProxyRadioButton.setSelectedState(state: false)
            
            DefaultsHelper.proxySetting = .noProxy
            
            self.hostTextField.isEnabled = false
            self.portTextField.isEnabled = false
            self.usernameTextField.isEnabled = false
            self.passwordTextField.isEnabled = false
            
            self.hostTextField.textColor = .lightGray
            self.portTextField.textColor = .lightGray
            self.usernameTextField.textColor = .lightGray
            self.passwordTextField.textColor = .lightGray
            
        case .systemProxy:
            self.useNoProxyRadioButton.setSelectedState(state: false)
            self.useSystemProxyRadioButton.setSelectedState(state: true)
            self.useManualProxyRadioButton.setSelectedState(state: false)
            
            DefaultsHelper.proxySetting = .systemProxy
            
            self.hostTextField.isEnabled = false
            self.portTextField.isEnabled = false
            self.usernameTextField.isEnabled = false
            self.passwordTextField.isEnabled = false
            
            self.hostTextField.textColor = .lightGray
            self.portTextField.textColor = .lightGray
            self.usernameTextField.textColor = .lightGray
            self.passwordTextField.textColor = .lightGray
            
        case .manualProxy:
            self.useNoProxyRadioButton.setSelectedState(state: false)
            self.useSystemProxyRadioButton.setSelectedState(state: false)
            self.useManualProxyRadioButton.setSelectedState(state: true)
            
            DefaultsHelper.proxySetting = .manualProxy
            
            self.hostTextField.isEnabled = true
            self.portTextField.isEnabled = true
            self.usernameTextField.isEnabled = true
            self.passwordTextField.isEnabled = true
            
            self.hostTextField.textColor = .black
            self.portTextField.textColor = .black
            self.usernameTextField.textColor = .black
            self.passwordTextField.textColor = .black
        }
    }
    
    @objc func handleState(_ sender: ProxyChoiceTapGestureRecognizer) {
        handleProxySetting(proxySetting: sender.proxySetting)
    }
    
    func saveProxySettings() {
        let savedProxySetting = DefaultsHelper.proxySetting
        if savedProxySetting == .noProxy {
            DefaultsHelper.proxyHost = ""
            DefaultsHelper.proxyPort = 80
            DefaultsHelper.proxyUsername = ""
            KeychainUtil.remove(key: proxyPasswordKey)
        } else if savedProxySetting == .systemProxy {
            ProxyUtil.updateSystemProxySettings()
        } else if savedProxySetting == .manualProxy {
            DefaultsHelper.proxyHost = hostTextField.text
            DefaultsHelper.proxyPort = Int(portTextField.text ?? "80") ?? 80
            DefaultsHelper.proxyUsername = usernameTextField.text
            let _ = KeychainUtil.save(key: proxyPasswordKey, info: (passwordTextField.text ?? "").data(using: .utf8) ?? Data())
        }
    }
    
    func updateUI() {
        DispatchQueue.main.async {
            let savedProxySetting = DefaultsHelper.proxySetting
            self.useNoProxyRadioButton.setSelectedState(state: savedProxySetting == .noProxy)
            self.useSystemProxyRadioButton.setSelectedState(state: savedProxySetting == .systemProxy)
            self.useManualProxyRadioButton.setSelectedState(state: savedProxySetting == .manualProxy)
            
            if savedProxySetting == .manualProxy {
                self.hostTextField.text = DefaultsHelper.proxyHost
                self.portTextField.text = String(DefaultsHelper.proxyPort)
                self.usernameTextField.text = DefaultsHelper.proxyUsername
                self.passwordTextField.text = String(data: KeychainUtil.retrieve(key: proxyPasswordKey) ?? Data(), encoding: .utf8)
            } else if savedProxySetting == .noProxy || savedProxySetting == .systemProxy {
                self.hostTextField.text = ""
                self.portTextField.text = "80"
                self.usernameTextField.text = ""
                self.passwordTextField.text = ""
            }

            // Detect which RadioButton was clicked
            if !(self.useNoProxyView.gestureRecognizers?.contains(where: { $0 is ProxyChoiceTapGestureRecognizer }) ?? false) {
                
                let tapGesture = ProxyChoiceTapGestureRecognizer(target: self, action: #selector(self.handleState(_:)))
                tapGesture.proxySetting = .noProxy
                self.useNoProxyView.addGestureRecognizer(tapGesture)
                self.useNoProxyView.isUserInteractionEnabled = true
            }
            
            if !(self.useSystemProxyView.gestureRecognizers?.contains(where: { $0 is ProxyChoiceTapGestureRecognizer }) ?? false) {
                
                let tapGesture = ProxyChoiceTapGestureRecognizer(target: self, action: #selector(self.handleState(_:)))
                tapGesture.proxySetting = .systemProxy
                self.useSystemProxyView.addGestureRecognizer(tapGesture)
                self.useSystemProxyView.isUserInteractionEnabled = true
            }
            
            if !(self.useManualProxyView.gestureRecognizers?.contains(where: { $0 is ProxyChoiceTapGestureRecognizer }) ?? false) {
                let tapGesture = ProxyChoiceTapGestureRecognizer(target: self, action: #selector(self.handleState(_:)))
                tapGesture.proxySetting = .manualProxy
                self.useManualProxyView.addGestureRecognizer(tapGesture)
                self.useManualProxyView.isUserInteractionEnabled = true
            }
            
            if let number = Int(self.portTextField.text ?? ""), self.isPortNumberValid(portNumber: number) {
                self.portErrorLabel.isHidden = true
            } else {
                self.portErrorLabel.isHidden = false
            }
            
            self.useNoProxyView.isAccessibilityElement = true
            self.useSystemProxyView.isAccessibilityElement = true
            self.useManualProxyView.isAccessibilityElement = true
            
            self.useNoProxyView.accessibilityLabel = L(.settingsProxyNoProxy)
            self.useSystemProxyView.accessibilityLabel = L(.settingsProxyUseSystem)
            self.useManualProxyView.accessibilityLabel = L(.settingsProxyUseManual)
            
            self.proxyTitle.text = L(.settingsProxyTitle)
            
            self.useNoProxyLabel.text = L(.settingsProxyNoProxy)
            self.useSystemProxyLabel.text = L(.settingsProxyUseSystem)
            self.useManualProxyLabel.text = L(.settingsProxyUseManual)
            
            self.hostLabel.text = L(.settingsProxyHost)
            self.portLabel.text = L(.settingsProxyPort)
            self.usernameLabel.text = L(.settingsProxyUsername)
            self.passwordLabel.text = L(.settingsProxyPassword)
            
            self.handleProxySetting(proxySetting: savedProxySetting)
        }
    }
    
    func presentDismissButton(_ textField: SettingsTextField) {
        textField.moppPresentDismissButton()
    }
    
    func setBorder(_ textField: SettingsTextField) {
        textField.layer.borderColor = UIColor.moppContentLine.cgColor
        textField.layer.borderWidth = 1
    }
    
    func isPortNumberValid(portNumber: Int) -> Bool {
        return (1...65535).contains(portNumber)
    }
    
    deinit {
        saveProxySettings()
        printLog("Deinit SettingsProxyCell")
    }
}

extension ProxyViewController: SettingsCellDelegate {
    func didStartEditingField(_ field: SigningCategoryViewController.FieldId, _ textField: UITextField) {
        switch field {
        case .proxy:
            currentlyEditingField = textField
            break
        default:
            break
        }
    }
    
    func didStartEditingField(_ field: SigningCategoryViewController.FieldId, _ indexPath: IndexPath) {
        currentlyEditingCell = indexPath
    }
    
    func didStartEditingField(_ field: FieldId, _ indexPath: IndexPath) {
        switch field {
        case .proxy:
            currentlyEditingCell = indexPath
            break
        }
    }
    
    func didEndEditingField(_ fieldId: SigningCategoryViewController.FieldId, with value: String) {
        currentlyEditingCell = nil
        UIAccessibility.post(notification: .screenChanged, argument: L(.settingsValueChanged))
    }
}

extension ProxyViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        DispatchQueue.main.async {
            textField.moveCursorToEnd()
        }
        
        switch textField {
        case hostTextField:
            showKeyboard(textFieldLabel: hostLabel, scrollView: scrollView)
        case portTextField:
            showKeyboard(textFieldLabel: portLabel, scrollView: scrollView)
        case usernameTextField:
            showKeyboard(textFieldLabel: usernameLabel, scrollView: scrollView)
        case passwordTextField:
            showKeyboard(textFieldLabel: passwordLabel, scrollView: scrollView)
        default:
            break
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case hostTextField:
            DefaultsHelper.proxyHost = textField.text
        case portTextField:
            DefaultsHelper.proxyPort = Int(textField.text ?? "80") ?? 80
        case usernameTextField:
            DefaultsHelper.proxyUsername = textField.text
        case passwordTextField:
            let _ = KeychainUtil.save(key: proxyPasswordKey, info: (textField.text ?? "").data(using: .utf8) ?? Data())
        default:
            break
        }
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: textField)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // Allow only numeric characters
        if textField == portTextField {
            
            let allowedCharacterSet = CharacterSet.decimalDigits
            let inputCharacterSet = CharacterSet(charactersIn: string)
            
            guard allowedCharacterSet.isSuperset(of: inputCharacterSet) else {
                return false
            }
            
            guard let text = textField.text as? NSString else { return false }
            let portNumber = text.replacingCharacters(in: range, with: string)
            guard let number = Int(portNumber) else { if portNumber.isEmpty { return true }; return false }
            
            // Check if port number is within range
            let isValidPortNumber = isPortNumberValid(portNumber: Int(number))
            portErrorLabel.isHidden = isValidPortNumber
            
            return true
        }
        return true
    }
}

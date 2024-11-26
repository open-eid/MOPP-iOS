//
//  SivaCertViewController.swift
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
import ASN1Decoder
import UniformTypeIdentifiers

enum SivaAccess: String, Codable {
    case defaultAccess
    case manualAccess
}

class SivaCertViewController: MoppViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var signatureValidationTitle: ScaledLabel!
    
    @IBOutlet weak var dismissButton: ScaledButton!
    
    @IBOutlet weak var certificateStackView: UIStackView!
    
    @IBOutlet weak var useDefaultAccessStackView: UIStackView!
    @IBOutlet weak var useDefaultAccessView: UIView!
    @IBOutlet weak var useDefaultAccessRadioButton: RadioButton!
    @IBOutlet weak var useDefaultAccessLabel: UILabel!
    
    @IBOutlet weak var useManuallyConfiguredAccessStackView: UIStackView!
    @IBOutlet weak var useManuallyConfiguredAccessView: UIView!
    @IBOutlet weak var useManuallyConfiguredAccessRadioButton: RadioButton!
    @IBOutlet weak var useManuallyConfiguredAccessLabel: UILabel!
    
    @IBOutlet weak var sivaUrlTextField: SettingsTextField!
    
    @IBOutlet weak var validationServiceCertificateTitle: ScaledLabel!
    
    @IBOutlet weak var issuedToLabel: ScaledLabel!
    @IBOutlet weak var validUntilLabel: ScaledLabel!

    @IBOutlet weak var addCertificateButton: ScaledLabel!

    @IBOutlet weak var showCertificateButton: ScaledLabel!

    @IBAction func dismissView(_ sender: ScaledButton) {
        dismiss(animated: true)
    }
    
    static let sivaFileFolder = "siva-cert"
    
    private var certificate: X509Certificate?
    private let configuration: MOPPConfiguration = Configuration.getConfiguration()

    var currentlyEditingCell: IndexPath?
    
    enum Section {
        case fields
    }
    
    enum FieldId {
        case sivaCert
    }
    
    var sections:[Section] = [.fields]
    
    var fields: [FieldId] = [
        .sivaCert
    ]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        
        dismissButton.setTitle(L(.closeButton))
        
        sivaUrlTextField.moppPresentDismissButton()
        sivaUrlTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        sivaUrlTextField.layer.borderWidth = 1
        sivaUrlTextField.delegate = self
        
        sivaUrlTextField.isAccessibilityElement = true
        sivaUrlTextField.accessibilityLabel = L(.settingsSivaServiceTitle)
        sivaUrlTextField.accessibilityUserInputLabels = [L(.voiceControlSivaService)]

        useDefaultAccessView.accessibilityUserInputLabels = [L(.voiceControlSivaDefaultAccess)]
        useManuallyConfiguredAccessView.accessibilityUserInputLabels = [L(.voiceControlSivaManualAccess)]
        
        certificate = CertUtil.getCertificate(folder: SivaCertViewController.sivaFileFolder, fileName: DefaultsHelper.sivaCertFileName ?? "")
        sivaUrlTextField.attributedPlaceholder = getSivaPlaceholder()
        
        guard let signatureValidationUITitle = signatureValidationTitle, let useDefaultAccessUIView = useDefaultAccessView, let useManuallyConfiguredAccessUIView = useManuallyConfiguredAccessView, let sivaUrlUITextfield: UITextField = sivaUrlTextField, let validationServiceCertificateUITitle = validationServiceCertificateTitle, let issuedToUILabel = issuedToLabel, let validUntilUILabel = validUntilLabel, let addCertificateUIButton = addCertificateButton, let showCertificateUIButton = showCertificateButton else {
            printLog("Unable to get sivaUrlTextField")
            return
        }
        
        if UIAccessibility.isVoiceOverRunning {
            self.accessibilityElements = [signatureValidationUITitle, useDefaultAccessUIView, useManuallyConfiguredAccessUIView, sivaUrlUITextfield, validationServiceCertificateUITitle, issuedToUILabel, validUntilUILabel, addCertificateUIButton, showCertificateUIButton]
        }
        
        updateUI()
    }
    
    @objc func addCertificate() {
        let documentPicker: UIDocumentPickerViewController = {
            let allowedDocumentTypes = [UTType.x509Certificate]
            let documentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: allowedDocumentTypes)
            documentPickerViewController.delegate = self
            documentPickerViewController.modalPresentationStyle = .overCurrentContext
            documentPickerViewController.allowsMultipleSelection = false
            return documentPickerViewController
        }()
        
        present(documentPicker, animated: true)
    }
    
    @objc func showCertificate() {
        guard let cert = self.certificate else { printLog("Unable to show certificate"); return }
        let certificateDetailsViewController = UIStoryboard.container.instantiateViewController(of: CertificateDetailViewController.self)
        let certificateDetail = SignatureCertificateDetail(x509Certificate: cert, secCertificate: nil)
        certificateDetailsViewController.certificateDetail = certificateDetail
        certificateDetailsViewController.useDefaultNavigationItems = false
        let certificateNC = UINavigationController(rootViewController: certificateDetailsViewController)
        certificateNC.modalPresentationStyle = .pageSheet

        if let certificatePC = certificateNC.presentationController as? UISheetPresentationController {
            certificatePC.detents = [
                .large()
            ]
            certificatePC.prefersGrabberVisible = true
        }

        certificateNC.view.backgroundColor = .white
        present(certificateNC, animated: true)
    }
    
    func getSivaPlaceholder() -> NSAttributedString {
        let attributes = [
            NSAttributedString.Key.foregroundColor: UIColor.moppLabelDarker,
            NSAttributedString.Key.font : UIFont(name: "Roboto-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        ]
        return NSAttributedString(string: configuration.SIVAURL, attributes: attributes)
    }
    
    func setAccessibilityElementsInStackView(stackView: UIStackView, isAccessibilityElement: Bool) {
        for subview in stackView.arrangedSubviews {
            subview.isAccessibilityElement = isAccessibilityElement
        }
    }
    
    @objc func handleState(_ sender: SivaChoiceTapGestureRecognizer) {
        switch sender.accessType {
        case .defaultAccess:
            self.useDefaultAccessRadioButton.setSelectedState(state: true)
            self.useManuallyConfiguredAccessRadioButton.setSelectedState(state: false)
            DefaultsHelper.sivaAccessState = .defaultAccess
            DefaultsHelper.sivaUrl = nil
            self.sivaUrlTextField.isEnabled = false
            certificateStackView.isHidden = true
            sivaUrlTextField.textColor = UIColor.lightGray
            if let sivaUrl = sivaUrlTextField.text, sivaUrl.isEmpty {
                sivaUrlTextField.text = ""
                sivaUrlTextField.attributedPlaceholder = getSivaPlaceholder()
            }
        case .manualAccess:
            self.useDefaultAccessRadioButton.setSelectedState(state: false)
            self.useManuallyConfiguredAccessRadioButton.setSelectedState(state: true)
            DefaultsHelper.sivaAccessState = .manualAccess
            self.sivaUrlTextField.isEnabled = true
            certificateStackView.isHidden = false
            sivaUrlTextField.textColor = UIColor.black
            if let sivaUrl = sivaUrlTextField.text, !sivaUrl.isEmpty {
                DefaultsHelper.sivaUrl = sivaUrlTextField.text
            } else {
                sivaUrlTextField.text = ""
            }
        }
    }
    
    func updateUI() {
        DispatchQueue.main.async {
            
            self.useDefaultAccessRadioButton.accessType = .defaultAccess
            self.useManuallyConfiguredAccessRadioButton.accessType = .manualAccess
            
            let savedAccessState = DefaultsHelper.sivaAccessState
            self.useDefaultAccessRadioButton.setSelectedState(state: savedAccessState == .defaultAccess)
            self.useManuallyConfiguredAccessRadioButton.setSelectedState(state: savedAccessState == .manualAccess)
            
            self.signatureValidationTitle.text = L(.settingsSivaServiceTitle)
            
            self.validationServiceCertificateTitle.text = L(.settingsSivaDefaultCertificateTitle)
            
            self.certificateStackView.isHidden = savedAccessState == .defaultAccess
            
            self.useDefaultAccessLabel.text = L(.settingsSivaDefaultAccessTitle)
            self.useManuallyConfiguredAccessLabel.text = L(.settingsSivaDefaultManualAccessTitle)
            
            self.sivaUrlTextField.isEnabled = savedAccessState != .defaultAccess
            
            let sivaUrl = DefaultsHelper.sivaUrl
            if sivaUrl == self.configuration.SIVAURL {
                self.sivaUrlTextField.text = ""
            } else {
                self.sivaUrlTextField.text = sivaUrl
            }
            
            // Detect which RadioButton was clicked
            if !(self.useDefaultAccessView.gestureRecognizers?.contains(where: { $0 is SivaChoiceTapGestureRecognizer }) ?? false) {
                
                let tapGesture = SivaChoiceTapGestureRecognizer(target: self, action: #selector(self.handleState(_:)))
                tapGesture.accessType = .defaultAccess
                self.useDefaultAccessView.addGestureRecognizer(tapGesture)
                self.useDefaultAccessView.isUserInteractionEnabled = true
            }
            
            if !(self.useManuallyConfiguredAccessView.gestureRecognizers?.contains(where: { $0 is SivaChoiceTapGestureRecognizer }) ?? false) {
                let tapGesture = SivaChoiceTapGestureRecognizer(target: self, action: #selector(self.handleState(_:)))
                tapGesture.accessType = .manualAccess
                self.useManuallyConfiguredAccessView.addGestureRecognizer(tapGesture)
                self.useManuallyConfiguredAccessView.isUserInteractionEnabled = true
            }
            
            self.useDefaultAccessView.isAccessibilityElement = true
            self.useManuallyConfiguredAccessView.isAccessibilityElement = true
            
            self.useDefaultAccessView.accessibilityLabel = L(.settingsSivaDefaultAccessTitle)
            
            self.useManuallyConfiguredAccessView.accessibilityLabel = L(.settingsSivaDefaultManualAccessTitle)
            
            self.issuedToLabel.text = L(.settingsTimestampCertIssuedToLabel)
            self.validUntilLabel.text = L(.settingsTimestampCertValidToLabel)
            
            self.addCertificateButton.isAccessibilityElement = true
            self.showCertificateButton.isAccessibilityElement = true
            self.addCertificateButton.text = L(.settingsTimestampCertAddCertificateButton)
            self.addCertificateButton.accessibilityLabel = self.addCertificateButton.text?.lowercased()
            self.addCertificateButton.font = .moppMedium
            self.addCertificateButton.textColor = .systemBlue
            self.addCertificateButton.isUserInteractionEnabled = true
            self.addCertificateButton.resetLabelProperties()
            
            self.showCertificateButton.text = L(.settingsTimestampCertShowCertificateButton)
            self.showCertificateButton.accessibilityLabel = self.showCertificateButton.text?.lowercased()
            self.showCertificateButton.font = .moppMedium
            self.showCertificateButton.textColor = .systemBlue
            self.showCertificateButton.isUserInteractionEnabled = true
            self.showCertificateButton.resetLabelProperties()
            
            if self.addCertificateButton.gestureRecognizers == nil || self.addCertificateButton.gestureRecognizers?.isEmpty == true {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.addCertificate))
                self.addCertificateButton.addGestureRecognizer(tapGesture)
            }
            
            if self.showCertificateButton.gestureRecognizers == nil || self.showCertificateButton.gestureRecognizers?.isEmpty == true {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.showCertificate))
                self.showCertificateButton.addGestureRecognizer(tapGesture)
            }
            
            self.addCertificateButton.accessibilityUserInputLabels = [self.addCertificateButton.text ?? ""]
            
            self.showCertificateButton.accessibilityUserInputLabels = [self.showCertificateButton.text ?? ""]
            
            guard let cert = self.certificate else { return }
            
            self.issuedToLabel.text = "\(self.issuedToLabel.text ?? L(.settingsTimestampCertIssuedToLabel)) \(cert.issuer(oid: .organizationName) ?? cert.issuer(oid: .subjectAltName) ?? cert.issuer(oid: .issuerAltName) ?? "-")"
            self.validUntilLabel.text = "\(self.validUntilLabel.text ?? L(.settingsTimestampCertValidToLabel)) \(MoppDateFormatter().dateToString(date: cert.notAfter, false))"
        }
    }
    
    func removeCertificate() {
        CertUtil.removeCertificate(folder: SivaCertViewController.sivaFileFolder, fileName: DefaultsHelper.sivaCertFileName ?? "")
        certificate = nil
        updateUI()
    }

    private func showErrorMessage(errorMessage: String, topViewController: UIViewController) {
        let errorDialog = AlertUtil.errorDialog(errorMessage: errorMessage, topViewController: topViewController)
        topViewController.present(errorDialog, animated: true)
    }
    
    private func showErrorMessage(fileName: String) {
        self.showErrorMessage(errorMessage: L(.fileImportNewFileOpeningFailedAlertMessage, [fileName]), topViewController: self)
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [addCertificateButton, showCertificateButton]
    }
}

extension SivaCertViewController: SettingsCellDelegate {
    func didStartEditingField(_ field: SigningCategoryViewController.FieldId, _ textField: UITextField) { return }
    
    func didStartEditingField(_ field: SigningCategoryViewController.FieldId, _ indexPath: IndexPath) {
        currentlyEditingCell = indexPath
    }
    
    func didStartEditingField(_ field: FieldId, _ indexPath: IndexPath) {
        switch field {
        case .sivaCert:
            currentlyEditingCell = indexPath
            break
        }
    }
    
    func didEndEditingField(_ fieldId: SigningCategoryViewController.FieldId, with value: String) {
        switch fieldId {
        case .sivaCert:
            DefaultsHelper.sivaUrl = DefaultsHelper.sivaUrl.isNilOrEmpty ? nil : value
            break
        default:
            break
        }
        currentlyEditingCell = nil
        UIAccessibility.post(notification: .screenChanged, argument: L(.settingsValueChanged))
    }
}

extension SivaCertViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if !urls.isEmpty {
            MoppFileManager.shared.saveFile(fileURL: urls[0], SivaCertViewController.sivaFileFolder) { isSaved, savedFileURL in
                
                guard let savedFile = savedFileURL else {
                    printLog("Failed to get saved SiVa cert file")
                    self.showErrorMessage(fileName: savedFileURL?.lastPathComponent ?? "-")
                    return
                }
                
                do {
                    if try savedFile.checkResourceIsReachable() {
                        self.certificate = try CertUtil.openCertificate(savedFile)
                        DefaultsHelper.sivaCertFileName = savedFile.lastPathComponent
                        self.updateUI()
                    }
                } catch let openFileError {
                    printLog("Failed to open '\(savedFile.lastPathComponent)'. Error: \(openFileError.localizedDescription)")
                    self.showErrorMessage(fileName: savedFile.lastPathComponent)
                    return
                }
            }
        }
    }
}

extension SivaCertViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.async {
            textField.moveCursorToEnd()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }
        DefaultsHelper.sivaUrl = text
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: textField)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }

        if textField.keyboardType == .default {
            if string.isEmpty && (text.count <= 1) {
                DefaultsHelper.sivaUrl = string
                removeCertificate()

                updateUI()
            }
            return true
        }
        if let text = textField.text as NSString? {
            let textAfterUpdate = text.replacingCharacters(in: range, with: string)
            return textAfterUpdate.isNumeric || textAfterUpdate.isEmpty
        }
        return true
    }
}


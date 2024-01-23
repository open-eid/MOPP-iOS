//
//  SettingsSivaCertCell.swift
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
import ASN1Decoder

enum SivaAccess: String, Codable {
    case defaultAccess
    case manualAccess
}

class SettingsSivaCertCell: UITableViewCell {
    
    static let sivaFileFolder = "siva-cert"
    
    private var certificate: X509Certificate?
    private let configuration: MOPPConfiguration = Configuration.getConfiguration()
    
    var field: SettingsViewController.Field!
    weak var delegate: SettingsCellDelegate!
    
    weak var topViewController: UIViewController?
    
    @IBOutlet weak var signatureValidationTitle: ScaledLabel!
    
    @IBOutlet weak var certificateStackView: UIStackView!
    @IBOutlet weak var certificateDataStackView: UIStackView!

    @IBOutlet weak var validationAccessStackView: UIStackView!
    @IBOutlet weak var validationAccessChoiceStackView: UIStackView!

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
    
    @IBOutlet weak var certificateButtonsStackView: UIStackView!
    @IBOutlet weak var addCertificateButton: ScaledButton!
    @IBOutlet weak var showCertificateButton: ScaledButton!
    
    
    @IBAction func addCertificate(_ sender: ScaledButton) {
        let documentPicker: UIDocumentPickerViewController = {
            let allowedDocumentTypes = ["public.x509-certificate"]
            let documentPickerViewController = UIDocumentPickerViewController(documentTypes: allowedDocumentTypes, in: .import)
            documentPickerViewController.delegate = self
            documentPickerViewController.modalPresentationStyle = .overCurrentContext
            documentPickerViewController.allowsMultipleSelection = false
            return documentPickerViewController
        }()
        
        topViewController?.present(documentPicker, animated: true)
    }
    
    @IBAction func showCertificate(_ sender: ScaledButton) {
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
        topViewController?.present(certificateNC, animated: true)
    }
    
    override func awakeFromNib() {
        sivaUrlTextField.moppPresentDismissButton()
        sivaUrlTextField.layer.borderColor = UIColor.moppContentLine.cgColor
        sivaUrlTextField.layer.borderWidth = 1
        sivaUrlTextField.delegate = self
        
        sivaUrlTextField.isAccessibilityElement = true
        sivaUrlTextField.accessibilityLabel = L(.settingsSivaServiceTitle)
        sivaUrlTextField.accessibilityUserInputLabels = [L(.voiceControlSivaService)]

        useDefaultAccessView.accessibilityUserInputLabels = [L(.voiceControlSivaDefaultAccess)]
        useManuallyConfiguredAccessView.accessibilityUserInputLabels = [L(.voiceControlSivaManualAccess)]
        
        guard let signatureValidationUITitle = signatureValidationTitle, let useDefaultAccessUIView = useDefaultAccessView, let useManuallyConfiguredAccessUIView = useManuallyConfiguredAccessView, let sivaUrlUITextfield: UITextField = sivaUrlTextField, let validationServiceCertificateUITitle = validationServiceCertificateTitle, let issuedToUILabel = issuedToLabel, let validUntilUILabel = validUntilLabel, let addCertificateUIButton = addCertificateButton, let showCertificateUIButton = showCertificateButton else {
            printLog("Unable to get sivaUrlTextField")
            return
        }
        
        if UIAccessibility.isVoiceOverRunning {
            self.accessibilityElements = [signatureValidationUITitle, useDefaultAccessUIView, useManuallyConfiguredAccessUIView, sivaUrlUITextfield, validationServiceCertificateUITitle, issuedToUILabel, validUntilUILabel, addCertificateUIButton, showCertificateUIButton]
        }
        
        updateUI()
    }
    
    func populate(with field:SettingsViewController.Field) {
        certificate = CertUtil.getCertificate(folder: SettingsSivaCertCell.sivaFileFolder, fileName: DefaultsHelper.sivaCertFileName ?? "")
        sivaUrlTextField.attributedPlaceholder = getSivaPlaceholder()
        self.field = field

        if let _ = certificate {
            updateUI()
        }
    }
    
    func getSivaPlaceholder() -> NSAttributedString {
        let attributes = [
            NSAttributedString.Key.foregroundColor: UIColor.placeholderText,
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
            DefaultsHelper.sivaUrl = configuration.SIVAURL
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
            
            self.addCertificateButton.setTitle(L(.settingsTimestampCertAddCertificateButton))
            self.addCertificateButton.accessibilityLabel = self.addCertificateButton.titleLabel?.text?.lowercased()
            self.showCertificateButton.setTitle(L(.settingsTimestampCertShowCertificateButton))
            self.showCertificateButton.accessibilityLabel = self.showCertificateButton.titleLabel?.text?.lowercased()
            self.showCertificateButton.mediumFont()
            self.addCertificateButton.mediumFont()
            
            self.addCertificateButton.accessibilityUserInputLabels = [self.addCertificateButton.titleLabel?.text ?? ""]
            
            self.showCertificateButton.accessibilityUserInputLabels = [self.showCertificateButton.titleLabel?.text ?? ""]
            
            guard let cert = self.certificate else { return }
            
            self.issuedToLabel.text = "\(self.issuedToLabel.text ?? L(.settingsTimestampCertIssuedToLabel)) \(cert.issuer(oid: .organizationName) ?? cert.issuer(oid: .subjectAltName) ?? cert.issuer(oid: .issuerAltName) ?? "-")"
            self.validUntilLabel.text = "\(self.validUntilLabel.text ?? L(.settingsTimestampCertValidToLabel)) \(MoppDateFormatter().dateToString(date: cert.notAfter, false))"
        }
    }
    
    private func showErrorMessage(errorMessage: String, topViewController: UIViewController) {
        let errorDialog = AlertUtil.errorDialog(errorMessage: errorMessage, topViewController: topViewController)
        topViewController.present(errorDialog, animated: true)
    }
    
    private func showErrorMessage(fileName: String) {
        let viewController = self.getViewController()
        if let tvc = viewController {
            self.showErrorMessage(errorMessage: L(.fileImportNewFileOpeningFailedAlertMessage, [fileName]), topViewController: tvc)
        }
    }
}

extension SettingsSivaCertCell: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if !urls.isEmpty {
            MoppFileManager.shared.saveFile(fileURL: urls[0], SettingsSivaCertCell.sivaFileFolder) { isSaved, savedFileURL in
                
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
    
    private func getViewController() -> UIViewController? {
        guard let tvc = self.topViewController else {
            printLog("Unable to get top view controller")
            return nil
        }
        
        return tvc
    }
}

extension SettingsSivaCertCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        var currentIndexPath = IndexPath(item: 1, section: 1)
        if let tableView = superview as? UITableView {
            if let indexPath = tableView.indexPath(for: self) {
                let section = indexPath.section
                let row = indexPath.row
                currentIndexPath = IndexPath(row: row, section: section)
            }
        }
        delegate.didStartEditingField(field.id, currentIndexPath)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate.didEndEditingField(field.id, with: textField.text ?? String())
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: textField)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }

        if textField.keyboardType == .default {
            if string.isEmpty && (text.count <= 1) {
                CertUtil.removeCertificate(folder: SettingsSivaCertCell.sivaFileFolder, fileName: DefaultsHelper.sivaCertFileName ?? "")
                certificate = nil
                DefaultsHelper.sivaUrl = string
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


//
//  SettingsTSACertCell.swift
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

import Foundation
import ASN1Decoder
import UniformTypeIdentifiers

class SettingsTSACertCell: UITableViewCell {
    
    static let tsaFileFolder = "tsa-cert"
    
    @IBOutlet weak var tsaCertStackView: UIStackView!
    @IBOutlet weak var tsaDataStackView: UIStackView!
    @IBOutlet weak var tsaCertLabelStackView: UIStackView!
    @IBOutlet weak var tsaCertButtonsStackView: UIStackView!
    
    @IBOutlet weak var titleLabel: ScaledLabel!
    
    @IBOutlet weak var issuedToLabel: ScaledLabel!
    @IBOutlet weak var validUntilLabel: ScaledLabel!
    
    // Using UILabel, as UIButton does not scale well with bigger fonts
    @IBOutlet weak var addCertificateButton: ScaledLabel!
    @IBOutlet weak var showCertificateButton: ScaledLabel!
    
    @objc func addCertificateButtonTapped() {
        let documentPicker: UIDocumentPickerViewController = {
            let allowedDocumentTypes = [UTType.x509Certificate]
            let documentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: allowedDocumentTypes)
            documentPickerViewController.delegate = self
            documentPickerViewController.modalPresentationStyle = .overCurrentContext
            documentPickerViewController.allowsMultipleSelection = false
            return documentPickerViewController
        }()
        
        topViewController?.present(documentPicker, animated: true)
    }
    
    @objc func showCertificateButtonTapped() {
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
    
    weak var topViewController: UIViewController?
    
    private var certificate: X509Certificate?
    
    var elements = [Any]()

    override func awakeFromNib() {
        updateUI()
        
        guard let titleUILabel = titleLabel, let issuedToUILabel = issuedToLabel, let validUntilUILabel = validUntilLabel, let addCertificateUIButton = addCertificateButton, let showCertificateUIButton = showCertificateButton else { return }
        
        self.accessibilityElements = [titleUILabel, issuedToUILabel, validUntilUILabel, addCertificateUIButton, showCertificateUIButton]
        
        elements = self.accessibilityElements ?? []
    }
    
    func populate() {
        self.certificate = CertUtil.getCertificate(folder: SettingsTSACertCell.tsaFileFolder, fileName: DefaultsHelper.tsaCertFileName ?? "")
        updateUI()
    }
    
    func updateUI() {
        DispatchQueue.main.async {
            self.titleLabel.text = L(.settingsTimestampCertTitle)
            self.tsaCertStackView.isAccessibilityElement = false
            self.tsaDataStackView.isAccessibilityElement = false
            self.tsaCertLabelStackView.isAccessibilityElement = false
            
            AccessibilityUtil.setAccessibilityElementsInStackView(stackView: self.tsaCertStackView, isAccessibilityElement: !DefaultsHelper.defaultSettingsSwitch)
            
            AccessibilityUtil.setAccessibilityElementsInStackView(stackView: self.tsaDataStackView, isAccessibilityElement: !DefaultsHelper.defaultSettingsSwitch)
            
            AccessibilityUtil.setAccessibilityElementsInStackView(stackView: self.tsaCertLabelStackView, isAccessibilityElement: !DefaultsHelper.defaultSettingsSwitch)
            
            AccessibilityUtil.setAccessibilityElementsInStackView(stackView: self.tsaCertButtonsStackView, isAccessibilityElement: !DefaultsHelper.defaultSettingsSwitch)
            
            self.issuedToLabel.text = L(.settingsTimestampCertIssuedToLabel)
            self.validUntilLabel.text = L(.settingsTimestampCertValidToLabel)
            
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
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.addCertificateButtonTapped))
                self.addCertificateButton.addGestureRecognizer(tapGesture)
            }
            
            if self.showCertificateButton.gestureRecognizers == nil || self.showCertificateButton.gestureRecognizers?.isEmpty == true {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.showCertificateButtonTapped))
                self.showCertificateButton.addGestureRecognizer(tapGesture)
            }
            
            guard let cert = self.certificate else { return }
            
            self.issuedToLabel.text = "\(self.issuedToLabel.text ?? L(.settingsTimestampCertIssuedToLabel)) \(cert.issuer(oid: .organizationName) ?? cert.issuer(oid: .subjectAltName) ?? cert.issuer(oid: .issuerAltName) ?? "-")"
            self.validUntilLabel.text = "\(self.validUntilLabel.text ?? L(.settingsTimestampCertValidToLabel)) \(MoppDateFormatter().dateToString(date: cert.notAfter, false))"
        }
    }
    
    func removeCertificate() {
        CertUtil.removeCertificate(folder: SettingsTSACertCell.tsaFileFolder, fileName: DefaultsHelper.tsaCertFileName ?? "")
        certificate = nil
        updateUI()
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

extension SettingsTSACertCell: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if !urls.isEmpty {
            MoppFileManager.shared.saveFile(fileURL: urls[0], SettingsTSACertCell.tsaFileFolder) { isSaved, savedFileURL in
                
                guard let savedFile = savedFileURL else {
                    printLog("Failed to get saved TSA cert file")
                    self.showErrorMessage(fileName: savedFileURL?.lastPathComponent ?? "-")
                    return
                }
                
                do {
                    if try savedFile.checkResourceIsReachable() {
                        self.certificate = try CertUtil.openCertificate(savedFile)
                        DefaultsHelper.tsaCertFileName = savedFile.lastPathComponent
                        self.updateUI()
                        UIAccessibility.post(notification: .layoutChanged, argument: self.showCertificateButton)
                    }
                } catch let openFileError {
                    printLog("Failed to open '\(savedFile.lastPathComponent)'. Error: \(openFileError.localizedDescription)")
                    self.showErrorMessage(fileName: savedFile.lastPathComponent)
                    return
                }
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        UIAccessibility.post(notification: .layoutChanged, argument: self.addCertificateButton)
    }
    
    private func getViewController() -> UIViewController? {
        guard let tvc = self.topViewController else {
            printLog("Unable to get top view controller")
            return nil
        }
        
        return tvc
    }
}

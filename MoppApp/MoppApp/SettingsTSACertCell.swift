//
//  SettingsTSACertCell.swift
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
import ASN1Decoder

class SettingsTSACertCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: ScaledLabel!
    
    @IBOutlet weak var issuedToLabel: ScaledLabel!
    @IBOutlet weak var validUntilLabel: ScaledLabel!
    
    @IBOutlet weak var addCertificateButton: ScaledButton!
    @IBOutlet weak var showCertificateButton: ScaledButton!
    
    @IBAction func addCertificate(_ sender: Any) {
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
    
    @IBAction func showCertificate(_ sender: Any) {
        guard let cert = self.certificate else { printLog("Unable to show certificate"); return }
        let certificateDetailsViewController = UIStoryboard.container.instantiateViewController(of: CertificateDetailViewController.self)
        let certificateDetail = SignatureCertificateDetail(x509Certificate: cert, secCertificate: nil)
        certificateDetailsViewController.certificateDetail = certificateDetail
        topViewController?.show(certificateDetailsViewController, sender: nil)
    }
    
    weak var topViewController: UIViewController?
    
    private var certificate: X509Certificate?

    override func awakeFromNib() {
        updateUI()
    }
    
    func populate() {
        self.certificate = TSACertUtil.getCertificate()
        if let _ = certificate {
            updateUI()
        }
    }
    
    func updateUI() {
        DispatchQueue.main.async {
            self.titleLabel.text = L(.settingsTimestampCertTitle)
            
            self.issuedToLabel.text = L(.settingsTimestampCertIssuedToLabel)
            self.validUntilLabel.text = L(.settingsTimestampCertValidToLabel)
            
            self.addCertificateButton.setTitle(L(.settingsTimestampCertAddCertificateButton))
            self.addCertificateButton.accessibilityLabel = self.addCertificateButton.titleLabel?.text?.lowercased()
            self.showCertificateButton.setTitle(L(.settingsTimestampCertShowCertificateButton))
            self.showCertificateButton.accessibilityLabel = self.showCertificateButton.titleLabel?.text?.lowercased()
            
            guard let cert = self.certificate else { return }
            
            self.issuedToLabel.text = "\(self.issuedToLabel.text ?? L(.settingsTimestampCertIssuedToLabel)) \(cert.issuer(oid: .organizationName) ?? cert.issuer(oid: OID(rawValue: "2.5.4.97") ?? .subjectAltName) ?? cert.issuer(oid: .issuerAltName) ?? "-")"
            self.validUntilLabel.text = "\(self.validUntilLabel.text ?? L(.settingsTimestampCertValidToLabel)) \(MoppDateFormatter().dateToString(date: cert.notAfter, false))"
        }
    }
    
    private func showErrorMessage(errorMessage: String, topViewController: UIViewController) {
        let errorDialog = AlertUtil.errorDialog(title: L(.errorAlertTitleGeneral), errorMessage: errorMessage, topViewController: topViewController)
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
            MoppFileManager.shared.saveFile(fileURL: urls[0], TSACertUtil.tsaFileFolder) { isSaved, savedFileURL in
                
                guard let savedFile = savedFileURL else {
                    printLog("Failed to get saved TSA cert file")
                    self.showErrorMessage(fileName: savedFileURL?.lastPathComponent ?? "-")
                    return
                }
                
                do {
                    if try savedFile.checkResourceIsReachable() {
                        self.certificate = try TSACertUtil.openCertificate(savedFile)
                        DefaultsHelper.tsaCertFileName = savedFile.lastPathComponent
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
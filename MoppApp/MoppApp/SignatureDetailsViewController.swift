//
//  SignatureDetailsViewController.swift
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
import Security
import ASN1Decoder
import CommonCrypto

private extension DataProtocol {
    func hexString() -> String {
        return self.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}

class SignatureDetailsViewController: MoppViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var moppLibSignature: MoppLibSignature?
    
    var signatureDetails = [SignatureDetail]()
    
    var warningDetail = WarningDetail()
    
    var signatureKind: ContainerSignatureCell.Kind = .signature

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItemForPushedViewController(title: signatureKind == .timestamp ? L(.timestampDetailsTitle) : L(.signatureDetailsTitle))
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.backgroundView = nil
        tableView.backgroundColor = UIColor.white
        
        // Remove buttons from tab bar
        if let landingViewController = LandingViewController.shared {
            landingViewController.presentButtons([])
        }
        
        setWarningsInfo()
        setSignerInfo()
    }
    
    private func setWarningsInfo() {
        let signatureStatus = moppLibSignature?.status

        if let status = signatureStatus, status != .Valid {
            let diagnosticsInfo = moppLibSignature?.diagnosticsInfo
            var warningDescription = ""
            if status == .Warning {
                if let signatureDetails = diagnosticsInfo, signatureDetails.contains("Signature digest weak") {
                    warningDescription = L(.containerSignatureStatusWarningReasonWeak)
                } else {
                    warningDescription = L(.containerSignatureStatusWarningReason)
                }
            } else if status == .NonQSCD {
                warningDescription = L(.containerSignatureStatusNonQscdReason)
            } else if status == .UnknownStatus {
                warningDescription = L(.containerSignatureStatusUnknownReason)
            } else if status == .Invalid {
                warningDescription = L(.containerSignatureStatusInvalidReason)
            }
            warningDetail = WarningDetail(warningHeader: L(.containerSignatureStatusReasonTitle), warningDescription: warningDescription)
            if let diagnostics = diagnosticsInfo {
                warningDetail.warningDetails = diagnostics
            }
        }
    }
    
    private func setSignerInfo() -> Void {
        signatureDetails.append(SignatureDetail(title: L(.signerCertificateIssuerLabel), value: moppLibSignature?.signersCertificateIssuer ?? ""))
        
        signatureDetails.append(
            SignatureDetail(
                title: L(.signersCertificateLabel),
                value: getX509Certificate(cert: moppLibSignature?.signingCertificate ?? Data())?.subject(oid: .commonName)?[0].replacingOccurrences(of: ",", with: ", ") ?? "",
                x509Certificate: getX509Certificate(cert: moppLibSignature?.signingCertificate ?? Data()),
                secCertificate: getSecCertificate(cert: moppLibSignature?.signingCertificate ?? Data())
            ))
        
        signatureDetails.append(SignatureDetail(title:  L(.signatureMethodLabel), value: moppLibSignature?.signatureMethod ?? ""))
        signatureDetails.append(SignatureDetail(title: L(.containerFormatLabel), value: moppLibSignature?.containerFormat ?? ""))
        signatureDetails.append(SignatureDetail(title: L(.signatureFormatLabel), value: moppLibSignature?.signatureFormat ?? ""))
        if let signatureSignedFileCount: Int = moppLibSignature?.signedFileCount {
            signatureDetails.append(SignatureDetail(title: L(.signedFileCountLabel), value: String(signatureSignedFileCount)))
        } else {
            signatureDetails.append(SignatureDetail(title: L(.signedFileCountLabel), value: ""))
        }
        signatureDetails.append(SignatureDetail(title: L(.signatureTimestampLabel), value: MoppDateFormatter().getDateTimeInCurrentTimeZone(dateString: moppLibSignature?.signatureTimestamp ?? "")))
        signatureDetails.append(SignatureDetail(title: L(.signatureTimestampUtcLabel), value: MoppDateFormatter().getDateTimeInUTCTimeZone(dateString: moppLibSignature?.signatureTimestampUTC ?? "")))
        signatureDetails.append(SignatureDetail(title: L(.hashValueOfSignatureLabel), value: moppLibSignature?.hashValueOfSignature.hexString() ?? ""))
        signatureDetails.append(SignatureDetail(title: L(.tsCertificateIssuerLabel), value: moppLibSignature?.tsCertificateIssuer ?? ""))
        
        signatureDetails.append(
            SignatureDetail(
                title: L(.tsCertificateLabel),
                value: getX509Certificate(cert: moppLibSignature?.tsCertificate ?? Data())?.subject(oid: .commonName)?[0] ?? "",
                x509Certificate: getX509Certificate(cert: moppLibSignature?.tsCertificate ?? Data()),
                secCertificate: getSecCertificate(cert: moppLibSignature?.tsCertificate ?? Data())))
        
        signatureDetails.append(SignatureDetail(title: L(.ocspCertificateIssuerLabel), value: moppLibSignature?.ocspCertificateIssuer ?? ""))
        
        signatureDetails.append(
            SignatureDetail(
                title: L(.ocspCertificateLabel),
                value: getX509Certificate(cert: moppLibSignature?.ocspCertificate ?? Data())?.subject(oid: .commonName)?[0] ?? "",
                x509Certificate: getX509Certificate(cert: moppLibSignature?.ocspCertificate ?? Data()),
                secCertificate: getSecCertificate(cert: moppLibSignature?.ocspCertificate ?? Data())))
        
        signatureDetails.append(SignatureDetail(title: L(.ocspTimeLabel), value: MoppDateFormatter().getDateTimeInCurrentTimeZone(dateString: moppLibSignature?.ocspTime ?? "")))
        signatureDetails.append(SignatureDetail(title: L(.ocspTimeUtcLabel), value: MoppDateFormatter().getDateTimeInUTCTimeZone(dateString: moppLibSignature?.ocspTimeUTC ?? "")))
        signatureDetails.append(SignatureDetail(title: L(.signersMobileTimeLabel), value: MoppDateFormatter().getDateTimeInUTCTimeZone(dateString: moppLibSignature?.signersMobileTimeUTC ?? "")))
    }


    func getX509Certificate(cert: Data) -> X509Certificate? {
        do {
            return try X509Certificate(data: cert)
        } catch let error {
            printLog("Invalid certificate. Error: \(error.localizedDescription)")
            return nil
        }
    }

    func getSecCertificate(cert: Data) -> SecCertificate? {
        guard let certificate: SecCertificate = SecCertificateCreateWithData(nil, (cert as NSData? ?? NSData())) else {
            return nil
        }

        return certificate
    }
}

extension SignatureDetailsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if warningDetail.warningDescription.isNilOrEmpty {
                return 0
            }
            return 1
        } else {
            return signatureDetails.count
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if warningDetail.warningDescription.isNilOrEmpty {
                return 0
            }
        }
        if indexPath.section == 1 {
            let signatureDetail = signatureDetails[indexPath.row]
            if signatureDetail.value.isEmpty {
                return 0
            }
        }
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withType: SignatureWarningsCell.self, for: indexPath)!
            cell.populate(signatureStatus: moppLibSignature?.status, warningDetail: warningDetail)
            cell.accessibilityUserInputLabels = [""]
            cell.onTechnicalInformationButtonTapped = {
                tableView.reloadData()
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withType: SignatureDetailsCell.self, for: indexPath)!
            cell.selectionStyle = .none
            cell.accessibilityTraits = [.staticText]
            cell.contentLabel.accessibilityTraits = [.staticText]
            let signatureDetail = signatureDetails[indexPath.row]
            if !signatureDetail.value.isEmpty {
                cell.populate(signatureDetail: signatureDetail)
                if signatureDetail.x509Certificate != nil && signatureDetail.secCertificate != nil {
                    cell.accessibilityTraits = [.button]
                    cell.contentLabel.accessibilityTraits = [.button]
                    cell.contentLabel.isUserInteractionEnabled = true
                    let tapRecognizer = SignatureDetailTapGesture(target: self, action: #selector(tapCertificateView(_:)))
                    tapRecognizer.signatureDetail = signatureDetail
                    cell.contentLabel.addGestureRecognizer(tapRecognizer)
                }
            }
            cell.accessibilityUserInputLabels = [""]
            return cell
        }
    }
    
    @objc func tapCertificateView(_ tap: SignatureDetailTapGesture) {
        if tap.signatureDetail?.x509Certificate != nil && tap.signatureDetail?.secCertificate != nil {
            let certificateDetailsViewController = UIStoryboard.container.instantiateViewController(of: CertificateDetailViewController.self)
            let certificateDetail = SignatureCertificateDetail(x509Certificate: tap.signatureDetail?.x509Certificate, secCertificate: tap.signatureDetail?.secCertificate)
            certificateDetailsViewController.certificateDetail = certificateDetail
            // Remove buttons from tab bar
            if let landingViewController = LandingViewController.shared {
                landingViewController.presentButtons([])
            }
            self.navigationController?.pushViewController(certificateDetailsViewController, animated: true)
        }
    }
}

class SignatureDetailTapGesture: UITapGestureRecognizer {
    var signatureDetail: SignatureDetail?
}

//
//  SignatureDetailsViewController.swift
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
import Security
import ASN1Decoder
import CommonCrypto

class SignatureDetailsViewController: MoppViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var moppLibSignature: MoppLibSignature?
    
    var signatureDetails = [SignatureDetail]()

    func getDownloadsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItemForPushedViewController(title: L(.signatureDetailsTitle))
        
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
        
        setSignerInfo()
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
        signatureDetails.append(SignatureDetail(title: L(.hashValueOfSignatureLabel), value: moppLibSignature?.hashValueOfSignature ?? ""))
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return signatureDetails.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let signatureDetail = signatureDetails[indexPath.row]
        if signatureDetail.value.isEmpty {
            return 0
        }
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    @objc func tapCertificateView(_ tap: SignatureDetailTapGesture) {
        if tap.signatureDetail?.x509Certificate != nil && tap.signatureDetail?.secCertificate != nil {
            let certificateDetailsViewController = UIStoryboard.container.instantiateViewController(of: CertificateDetailViewController.self)
            let certificateDetail = SignatureCertificateDetail(x509Certificate: tap.signatureDetail?.x509Certificate, secCertificate: tap.signatureDetail?.secCertificate)
            certificateDetailsViewController.certificateDetail = certificateDetail
            self.navigationController?.pushViewController(certificateDetailsViewController, animated: true)
        }
    }
}

class SignatureDetailTapGesture: UITapGestureRecognizer {
    var signatureDetail: SignatureDetail?
}

//
//  CertificateDetailViewController.swift
//  MoppApp
//
/*
 * Copyright 2020 Riigi Infosüsteemide Amet
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

class CertificateDetailViewController: MoppViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var certificateDetail: SignatureCertificateDetail?
    
    var certificateSections = [CertificateSection]()
    
    enum HashType {
        case SHA1
        case SHA256
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCertificateDetails()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Top bar title and back button
        setupNavigationItemForPushedViewController(title: L(.certificateDetailsTitle))
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.sectionHeaderHeight = 84
        tableView.backgroundView = nil
        tableView.backgroundColor = UIColor.white
        
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        // Remove buttons from tab bar
        if let landingViewController = LandingViewController.shared {
            landingViewController.presentButtons([])
        }
    }
    
    func setCertificateDetails() -> Void {
        certificateSections.append(CertificateSection(header: L(.subjectName), certificateDetail: [
            CertificateDetail(title: L(.countryOrRegion), value: certificateDetail?.x509Certificate?.subject(oid: .countryName)?[0] ?? ""),
            CertificateDetail(title: L(.organisation), value: certificateDetail?.x509Certificate?.subject(oid: .organizationName)?[0] ?? ""),
            CertificateDetail(title: L(.organisationalUnit), value: certificateDetail?.x509Certificate?.subject(oid: .organizationalUnitName)?[0] ?? ""),
            CertificateDetail(title: L(.commonName), value: certificateDetail?.x509Certificate?.subject(oid: .commonName)?[0].replacingOccurrences(of: ",", with: ", ") ?? ""),
            CertificateDetail(title: L(.surname), value: certificateDetail?.x509Certificate?.subject(oid: .surname)?[0] ?? ""),
            CertificateDetail(title: L(.givenName), value: certificateDetail?.x509Certificate?.subject(oid: .givenName)?[0] ?? ""),
            CertificateDetail(title: L(.serialNumber), value: certificateDetail?.x509Certificate?.subject(oid: .serialNumber)?[0] ?? ""),
            CertificateDetail(title: L(.emailAddress), value: certificateDetail?.x509Certificate?.subject(oid: .emailAddress)?[0] ?? "")
        ]))
        
        var issuerNameDetails = [CertificateDetail]()
        
        issuerNameDetails.append(CertificateDetail(title: L(.countryOrRegion), value: certificateDetail?.x509Certificate?.issuer(oid: .countryName) ?? ""))
        issuerNameDetails.append(CertificateDetail(title: L(.organisation), value: certificateDetail?.x509Certificate?.issuer(oid: .organizationName) ?? ""))
        if certificateDetail?.x509Certificate?.issuerOIDs.contains("2.5.4.97") ?? false {
            issuerNameDetails.append(CertificateDetail(title: L(.otherName), value: certificateDetail?.x509Certificate?.issuer(oid: OID(rawValue: "2.5.4.97") ?? .subjectAltName) ?? ""))
        }
        issuerNameDetails.append(CertificateDetail(title: L(.commonName), value: certificateDetail?.x509Certificate?.issuer(oid: .commonName) ?? ""))
        issuerNameDetails.append(CertificateDetail(title: L(.serialNumber), value: dataToHex(hashBytes: [UInt8](certificateDetail?.x509Certificate?.serialNumber ?? Data()))))
        issuerNameDetails.append(CertificateDetail(title: L(.version), value: "\(certificateDetail?.x509Certificate?.version ?? Int())"))
        issuerNameDetails.append(CertificateDetail(title: L(.signatureAlgorithm), value: "\(certificateDetail?.x509Certificate?.sigAlgName ?? "") (\(certificateDetail?.x509Certificate?.sigAlgOID ?? ""))"))
        issuerNameDetails.append(CertificateDetail(title: L(.parameters), value: certificateDetail?.x509Certificate?.sigAlgParams == nil ? "None" : "\(String(data: certificateDetail?.x509Certificate?.sigAlgParams ?? Data(), encoding: .utf8) ?? "None")"))
        issuerNameDetails.append(CertificateDetail(title: L(.notValidBefore), value: MoppDateFormatter().dateToString(date: certificateDetail?.x509Certificate?.notBefore)))
        issuerNameDetails.append(CertificateDetail(title: L(.notValidAfter), value: MoppDateFormatter().dateToString(date: certificateDetail?.x509Certificate?.notAfter)))
        
        
        certificateSections.append(CertificateSection(header: L(.issuerName), certificateDetail: issuerNameDetails))
        
        
        certificateSections.append(CertificateSection(header: L(.publicKeyInfo), certificateDetail: [
            CertificateDetail(title: L(.algorithm), value: "\(certificateDetail?.x509Certificate?.publicKey?.algName ?? "") (\(certificateDetail?.x509Certificate?.publicKey?.algOid ?? ""))"),
            CertificateDetail(title: L(.parameters), value: certificateDetail?.x509Certificate?.sigAlgParams == nil ? "None" : "\(String(data: certificateDetail?.x509Certificate?.sigAlgParams ?? Data(), encoding: .utf8) ?? "None")"),
            CertificateDetail(title: L(.publicKey), value: "\(getBytesCount(bytes: [UInt8](certificateDetail?.x509Certificate?.publicKey?.key ?? Data()))) bytes: \(dataToHex(hashBytes: [UInt8](certificateDetail?.x509Certificate?.publicKey?.key ?? Data())))"),
            CertificateDetail(title: L(.keyUsage), value: "\(certificateDetail?.x509Certificate?.publicKey?.algParams ?? "") (\(certificateDetail?.x509Certificate?.publicKey?.algOid ?? ""))"),
            CertificateDetail(title: L(.signature), value: "\(getBytesCount(bytes: [UInt8](certificateDetail?.x509Certificate?.signature ?? Data()))) bytes: \(dataToHex(hashBytes: [UInt8](certificateDetail?.x509Certificate?.signature ?? Data())))")
        ]))
        
        var certificateExtensionDetails = [CertificateDetail]()
        
        if let criticalOIDs = certificateDetail?.x509Certificate?.criticalExtensionOIDs {
            for cOID in criticalOIDs {
                let extensionObject: X509Extension? = certificateDetail?.x509Certificate?.extensionObject(oid: cOID)
                
                certificateExtensionDetails.append(CertificateDetail(title: L(.certificateExtension), value: "\(extensionObject?.name ?? "") (\(extensionObject?.oid ?? ""))"))
                
                certificateExtensionDetails.append(CertificateDetail(title: "\t" + L(.critical), value: "\(extensionObject?.isCritical.description ?? "")", isSubValue: true))
                
                let keyUsages: [String] = getKeyUsages(keyUsages: certificateDetail?.x509Certificate?.keyUsage ?? []) ?? []
                let listOfKeyUsages: String = keyUsages.joined(separator: ", ")
                
                certificateExtensionDetails.append(CertificateDetail(title: "\t" + L(.usage), value: listOfKeyUsages, isSubValue: true))
            }
        }
        
        if let nonCriticalOIDs = certificateDetail?.x509Certificate?.nonCriticalExtensionOIDs {
            for nOID in nonCriticalOIDs {
                let extensionObject: X509Extension? = certificateDetail?.x509Certificate?.extensionObject(oid: nOID)
                certificateExtensionDetails.append(CertificateDetail(title: L(.certificateExtension), value: "\(extensionObject?.name ?? "") (\(extensionObject?.oid ?? ""))"))
                certificateExtensionDetails.append(CertificateDetail(title: "\t" + L(.critical), value: "\(extensionObject?.isCritical.description ?? "")", isSubValue: true))
                
                if let extValue = extensionObject?.value {
                    if let extData = extValue as? Data {
                        certificateExtensionDetails.append(CertificateDetail(title: "\t" + L(.keyId), value: "\(dataToHex(hashBytes: [UInt8](extData)))", isSubValue: true))
                    }
                    
                    if let extString = extValue as? String {
                        if extString.starts(with: "http") || extString.starts(with: "https") {
                            certificateExtensionDetails.append(CertificateDetail(title: "\t" + L(.uri), value: extString, isSubValue: true))
                        }
                    }
                }
                
                if extensionObject?.name == "authorityInfoAccess" && certificateDetail?.x509Certificate?.extensionObject(oid: .ocsp)?.name != nil {
                    certificateExtensionDetails.append(CertificateDetail(title: "\t" + L(.method), value: certificateDetail?.x509Certificate?.extensionObject(oid: .ocsp)?.name ?? "", isSubValue: true))
                    if let extValue = certificateDetail?.x509Certificate?.extensionObject(oid: .ocsp)?.value as? String {
                        if extValue.starts(with: "http") || extValue.starts(with: "https") {
                            certificateExtensionDetails.append(CertificateDetail(title: "\t" + L(.uri), value: extValue, isSubValue: true))
                        }
                    }
                }
                
                if extensionObject?.name == "authorityInfoAccess" && certificateDetail?.x509Certificate?.extensionObject(oid: .caIssuers)?.name != nil {
                    certificateExtensionDetails.append(CertificateDetail(title: "\t" + L(.method), value: certificateDetail?.x509Certificate?.extensionObject(oid: .caIssuers)?.name ?? "", isSubValue: true))
                    
                    if let extValue = certificateDetail?.x509Certificate?.extensionObject(oid: .caIssuers)?.value as? String {
                        if extValue.starts(with: "http") || extValue.starts(with: "https") {
                            certificateExtensionDetails.append(CertificateDetail(title: "\t" + L(.uri), value: extValue, isSubValue: true))
                        }
                    }
                }
            }
        }
        
        certificateSections.append(CertificateSection(header: L(.certificateExtensions), certificateDetail: certificateExtensionDetails))
        
        certificateSections.append(CertificateSection(header: L(.fingerprints), certificateDetail: [
            CertificateDetail(title: L(.sha256), value: getFingerprintHash(cert: certificateDetail?.x509Certificate?.signature ?? Data(), secCertificate: certificateDetail?.secCertificate ?? nil, hashType: .SHA256) ?? ""),
            CertificateDetail(title: L(.sha1), value: getFingerprintHash(cert: certificateDetail?.x509Certificate?.signature ?? Data(), secCertificate: certificateDetail?.secCertificate ?? nil, hashType: .SHA1) ?? "")
        ]))
        
        tableView.reloadData()
    }
    
    func getFingerprintHash(cert: Data, secCertificate: SecCertificate?, hashType: HashType) -> String? {
        
        guard let certificate: SecCertificate = secCertificate else { return nil }
        
        let cerData: CFData = SecCertificateCopyData(certificate)
        let certificateData: Data? = cerData as Data?
        var hash: [UInt8] = [UInt8] (repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        guard let cData = certificateData else { return nil }
        
        switch hashType {
        case .SHA256:
            _ = cData.withUnsafeBytes {
                CC_SHA256($0.baseAddress, UInt32(cData.count), &hash)
            }
        case .SHA1:
            _ = cData.withUnsafeBytes {
                CC_SHA1($0.baseAddress, UInt32(cData.count), &hash)
            }
        }
        
        return dataToHex(hashBytes: hash)
    }
    
    func dataToHex(hashBytes: [UInt8]) -> String {
        var dataInHex: String = ""
        for byte in hashBytes {
            if byte != 00 {
                dataInHex = dataInHex.appendingFormat(dataInHex.isEmpty ? "%02X" : " %02X", UInt8(byte))
            }
        }
        
        return dataInHex
    }
    
    func getBytesCount(bytes: [UInt8]?) -> Int {
        guard let bytesArray = bytes else {
            return 0
        }
        return [UInt8](bytesArray).count
    }
    
    func getKeyUsages(keyUsages: [Bool]) -> [String]? {
        var kUsages: [String] = [String]()
        
        for (index, keyUsage) in keyUsages.enumerated() {
            if keyUsage {
                if let keyUsageDescription = getKeyUsageDescription(number: index) {
                    kUsages.append(keyUsageDescription)
                }
            }
        }
        
        return kUsages
    }
    
    func getKeyUsageDescription(number: Int) -> String? {
        switch number {
        case 0:
            return "Digital Signature"
        case 1:
            return "Non-Repudiation"
        case 2:
            return "Key Encipherment"
        case 3:
            return "Data Encipherment"
        case 4:
            return "Key Agreement"
        case 5:
            return "Key Cert Sign"
        case 6:
            return "cRL Sign"
        case 7:
            return "Encipher Only"
        case 8:
            return "Decipher Only"
        default:
            return ""
        }
    }
}

extension CertificateDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return certificateSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return certificateSections[section].certificateDetail.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let certificateDetail = certificateSections[indexPath.section].certificateDetail[indexPath.row]
        if certificateDetail.value.isEmpty {
            return 0
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return certificateSections[section].header
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let tableViewFrame = tableView.frame
        
        let headerLabel = ScaledLabel()
        headerLabel.frame = CGRect(x: 15, y: 0, width: tableViewFrame.size.width - 20, height: 80)
        headerLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
        headerLabel.textColor = UIColor.moppTitle
        
        let headerUiView = UIView(frame: CGRect(x: 0, y: 0, width: tableViewFrame.size.width, height: tableViewFrame.size.height))
        headerUiView.addSubview(headerLabel)
        
        return headerUiView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withType: CertificateDetailsCell.self, for: indexPath)!
        cell.selectionStyle = .none
        let certificateDetail = certificateSections[indexPath.section].certificateDetail[indexPath.row]
        if !certificateDetail.value.isEmpty {
            cell.populate(certificateDetail: certificateDetail)
        }
        cell.accessibilityUserInputLabels = [""]
        return cell
    }
}

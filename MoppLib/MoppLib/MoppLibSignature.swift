//
//  MoppLibSignature.swift
//  MoppLib
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

@objc public enum MoppLibSignatureStatus: Int {
    case Valid
    case Warning
    case NonQSCD
    case Invalid
    case UnknownStatus
}

@objcMembers
public class MoppLibSignature: NSObject {
    public var pos: uint = 0
    public var subjectName: String = ""
    public var timestamp: Date?
    public var status: MoppLibSignatureStatus = .UnknownStatus
    public var diagnosticsInfo: String = ""
    public var issuerName: String = ""
    public var roleAndAddressData = MoppLibRoleAddressData(roles: [], city: "", state: "", country: "", zip: "")

    public var signersCertificateIssuer: String = ""
    public var signingCertificate: Data = Data()
    public var signatureMethod: String = ""
    public var containerFormat: String = ""
    public var signatureFormat: String = ""
    public var signedFileCount: Int = 0
    public var signatureTimestampUTC: Date?
    public var hashValueOfSignature: Data = Data()
    public var tsCertificateIssuer: String = ""
    public var tsCertificate: Data = Data()
    public var ocspCertificateIssuer: String = ""
    public var ocspCertificate: Data = Data()
    public var ocspTimeUTC: Date?
    public var signersMobileTimeUTC: Date?
}

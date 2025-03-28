//
//  Addressee.swift
//  CryptoLib
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

public class Addressee: NSObject {
    @objc public var data: Data
    public let identifier: String
    public let givenName: String?
    public let surname: String?
    public let certType: CertType
    public var validTo: Date?

    @objc public init(cn: String, certType: CertType, validTo: Date?, data: Data) {
        let split = cn.split(separator: ",").map { String($0) }
        if split.count > 1 {
            surname = split[0]
            givenName = split[1]
            identifier = split[2]
        } else {
            surname = nil
            givenName = nil
            identifier = cn
        }
        self.certType = certType
        self.validTo = validTo
        self.data = data
    }

    @objc convenience public init(cn: String, pub: Data) {
        self.init(cn: cn, certType: .UnknownType, validTo: nil, data: pub)
    }

    convenience init(cert: Data) {
        let x509 = try? X509Certificate(der: cert)
        self.init(cn: x509?.subject(oid: OID.commonName)?.joined(separator: ",") ?? "", certType: x509?.certType() ?? .UnknownType, validTo: x509?.notAfter, data: cert)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Addressee else { return false }
        return
            data == other.data &&
            identifier == other.identifier &&
            givenName == other.givenName &&
            surname == other.surname &&
            certType == other.certType &&
            validTo == other.validTo
    }
}

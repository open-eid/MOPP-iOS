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

import ASN1Decoder

public class Addressee: NSObject {
    @objc public var data: Data
    public let identifier: String
    public let givenName: String?
    public let surname: String?
    public let serialNumber: String?
    public let certType: CertType
    public var validTo: Date?

    init(cert: Data, x509: X509Certificate?) {
        data = cert
        let cn = x509?.subject(oid: .commonName)?.joined(separator: ",") ?? ""
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
        serialNumber = x509?.subject(oid: .serialNumber)?.joined(separator: ",")
        certType = x509?.certType() ?? .UnknownType
        validTo = x509?.notAfter
    }

    convenience init(cert: Data) {
        self.init(cert: cert, x509: try? X509Certificate(der: cert))
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

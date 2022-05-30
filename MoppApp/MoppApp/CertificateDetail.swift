//
//  CertificateDetail.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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

struct CertificateSection {
    var header: String
    var certificateDetail: [CertificateDetail]
    
    init(header: String, certificateDetail: [CertificateDetail]) {
        self.header = header
        self.certificateDetail = certificateDetail
    }
}

struct SignatureCertificateDetail {
    var x509Certificate: X509Certificate?
    var secCertificate: SecCertificate?
    
    init(x509Certificate: X509Certificate?, secCertificate: SecCertificate?) {
        self.x509Certificate = x509Certificate
        self.secCertificate = secCertificate
    }
}

struct CertificateDetail {
    var title: String
    var value: String
    var isSubValue = false
    
    init(title: String, value: String) {
        self.title = title
        self.value = value
    }
    
    init(title: String, value: String, isSubValue: Bool) {
        self.title = title
        self.value = value
        self.isSubValue = isSubValue
    }
}

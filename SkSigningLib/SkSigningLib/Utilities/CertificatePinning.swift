//
//  CertificatePinning.swift
//  SkSigningLib
//
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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

class CertificatePinning {
    
    func certificatePinning(trustedCertificates: [String], challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            return completionHandler(.cancelAuthenticationChallenge, nil)
        }
        if let serverTrust = challenge.protectionSpace.serverTrust {
            var trustResult = SecTrustResultType.invalid
            SecTrustEvaluate(serverTrust, &trustResult)
            if trustResult != .proceed && trustResult != .unspecified {
                return completionHandler(.cancelAuthenticationChallenge, nil)
            }
            
            guard let secTrustServerCert = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
                return completionHandler(.cancelAuthenticationChallenge, nil)
            }
            
            let secCertificateData = SecCertificateCopyData(secTrustServerCert) as Data
            
            if isCertificateTrusted(trustedCertificates: trustedCertificates, serverCertData: secCertificateData) {
                return completionHandler(.useCredential, URLCredential(trust: serverTrust))
            }
            
            return completionHandler(.cancelAuthenticationChallenge, nil)
        } else {
            return completionHandler(.cancelAuthenticationChallenge, nil)
        }
        
    }
    
    func isCertificateTrusted(trustedCertificates: [String], serverCertData: Data) -> Bool {
        for cert in trustedCertificates {
            guard let domainCertData = Data(base64Encoded: cert) else {
                return false
            }
            
            if (domainCertData == serverCertData) {
                return true
            }
        }
        return false;
    }
}

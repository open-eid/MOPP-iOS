//
//  SignatureVerifier.swift
//  MoppApp
//
/*
 * Copyright 2021 Riigi Infosüsteemi Amet
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

import SwiftyRSA

class SignatureVerifier {
    
    func isSignatureCorrect(configData: String, publicKey: String, signature: String) throws {
        guard let data = Data(base64Encoded: removeHeaderAndFooterFromRSACertificate(certificate: publicKey)) else { return }
        
        do {
            let confData = try ClearMessage(string: configData, using: .utf8)
            let signatureBase64 = try Signature(base64Encoded: removeAllWhitespace(data: signature))
            let isVerificationSuccessful: Bool = try confData.verify(with: PublicKey(data: data), signature: signatureBase64, digestType: .sha512)
            
            if isVerificationSuccessful == false {
                MSLog("Signature verification unsuccessful")
                throw Exception("Signature verification unsuccessful")
            }
            
        } catch {
            throw error
        }
    }
    
    func hasSignatureChanged(oldSignature: String, newSignature: String) -> Bool {
        return removeAllWhitespace(data: oldSignature) != removeAllWhitespace(data: newSignature)
    }
    
    private func removeHeaderAndFooterFromRSACertificate(certificate: String) -> String {
        let header = "-----BEGIN RSA PUBLIC KEY-----"
        let footer = "-----END RSA PUBLIC KEY-----"
        let cleanCert = removeAllWhitespace(data: certificate.replacingOccurrences(of: header, with: "")
            .replacingOccurrences(of: footer, with: ""))
        
        return cleanCert
    }
    
    private func removeAllWhitespace(data: String) -> String {
        return data.filter { !" \n\t\r".contains($0) }
    }
}

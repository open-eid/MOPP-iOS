//
//  SignatureVerifier.swift
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

import Security

class SignatureVerifier {
    
    static func isSignatureCorrect(configData: String, publicKey: String, signature: String) throws {
        guard let sigData = fromBase64(signature) else {
            throw Exception("Invalid signature")
        }
        guard let pubKey = fromBase64(publicKey
            .replacingOccurrences(of: "-----BEGIN RSA PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PUBLIC KEY-----", with: "")) else {
            throw Exception("Invalid public key")
        }
        let parameters: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecReturnPersistentRef: false
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(pubKey as CFData, parameters as CFDictionary, &error) else {
            printLog("Failed to create key: \(error!.takeRetainedValue())")
            throw Exception("Failed to create key: \(error!.takeRetainedValue())")
        }
        let algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA512
        let result = SecKeyVerifySignature(key, algorithm, Data(configData.utf8) as CFData, sigData as CFData, &error)
        if !result {
            print("Verification error: \(error!.takeRetainedValue())")
            throw Exception("Signature verification unsuccessful")
        }
    }

    static func hasSignatureChanged(oldSignature: String, newSignature: String) -> Bool {
        fromBase64(oldSignature) != fromBase64(newSignature)
    }

    static private func fromBase64(_ input: String) -> Data? {
        Data(base64Encoded: input, options: .ignoreUnknownCharacters)
    }
}

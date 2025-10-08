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

import CryptoKit

class SignatureVerifier {
    
    static func isSignatureCorrect(configData: String, publicKey: String, signature: String) throws {
        guard let sigData = fromBase64(signature) else {
            throw Exception("Invalid signature")
        }
        guard let pubKey = fromBase64(publicKey
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")) else {
            throw Exception("Invalid public key")
        }
        let result: Bool
        switch pubKey.count {
        case 80...100:
            let key = try P256.Signing.PublicKey(derRepresentation: pubKey)
            let sig = try P256.Signing.ECDSASignature(derRepresentation: sigData)
            result = key.isValidSignature(sig, for: Data(configData.utf8))
        case 110...130:
            let key = try P384.Signing.PublicKey(derRepresentation: pubKey)
            let sig = try P384.Signing.ECDSASignature(derRepresentation: sigData)
            result = key.isValidSignature(sig, for: Data(configData.utf8))
        case 150...170:
            let key = try P521.Signing.PublicKey(derRepresentation: pubKey)
            let sig = try P521.Signing.ECDSASignature(derRepresentation: sigData)
            result = key.isValidSignature(sig, for: Data(configData.utf8))
        default:
            throw Exception("Unknown key size")
        }
        if !result {
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

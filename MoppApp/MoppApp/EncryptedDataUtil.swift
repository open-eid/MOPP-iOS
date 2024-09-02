//
//  EncryptedDataUtil.swift
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

import Foundation
import CryptoKit

struct EncryptedDataUtil {
    
    static func applicationSupportDirectory() -> URL? {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }
    
    static func storeKey(_ key: SymmetricKey, to url: URL) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        try keyData.write(to: url, options: .atomic)
    }
    
    @discardableResult
    static func saveSymmetricKeyToAppSupport(fileName: String) throws -> URL {
        guard let appSupportDirectory = applicationSupportDirectory() else {
            throw NSError(domain: "EncryptedDataUtil", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to locate Application Support directory"])
        }
        
        let symmetricKeyURL = appSupportDirectory.appendingPathComponent(fileName)
        let symmetricKey = SymmetricKey(size: .bits256)
        
        try storeKey(symmetricKey, to: symmetricKeyURL)
        
        return symmetricKeyURL
    }
    
    static func encryptSecret(_ secret: String, with key: SymmetricKey) -> Data? {
        guard let secretData = secret.data(using: .utf8) else { return nil }
        
        do {
            let sealedBox = try ChaChaPoly.seal(secretData, using: key)
            return sealedBox.combined
        } catch {
            printLog("Unable to encrypt secret: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func getSymmetricKey(fileName: String) throws -> SymmetricKey {
        guard let appSupportDirectory = applicationSupportDirectory() else {
            throw NSError(domain: "EncryptedDataUtil", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to locate Application Support directory"])
        }
        
        let symmetricKeyURL = appSupportDirectory.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: symmetricKeyURL.path) else {
            throw NSError(domain: "EncryptedDataUtil", code: 3, userInfo: [NSLocalizedDescriptionKey: "Key file does not exist"])
        }
        
        let keyData = try Data(contentsOf: symmetricKeyURL)
        return SymmetricKey(data: keyData)
    }
    
    static func decryptSecret(_ data: Data, with symmetricKey: SymmetricKey) -> String? {
        do {
            let sealedBox = try ChaChaPoly.SealedBox(combined: data)
            let decryptedData = try ChaChaPoly.open(sealedBox, using: symmetricKey)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            printLog("Unable to decrypt encrypted secret: \(error.localizedDescription)")
            return nil
        }
    }
}

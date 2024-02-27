//
//  KeychainUtil.swift
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
import Security

class KeychainUtil {
    static func save(key: String, info: String) -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return false }
        if let data = info.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: bundleIdentifier,
                kSecAttrAccount as String: "\(bundleIdentifier).\(key)",
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            SecItemDelete(query as CFDictionary)
            let status = SecItemAdd(query as CFDictionary, nil)
            
            return status == errSecSuccess
        }
        return false
    }
    
    static func retrieve(key: String) -> String? {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return nil }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: bundleIdentifier,
            kSecAttrAccount as String: "\(bundleIdentifier).\(key)",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        var infoData: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &infoData)
        
        if status == errSecSuccess, let data = infoData as? Data {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
    
    static func remove(key: String) {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: bundleIdentifier,
            kSecAttrAccount as String: "\(bundleIdentifier).\(key)"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess {
            printLog("Error removing key from Keychain: \(status)")
        }
    }
}

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
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: bundleIdentifier,
                kSecAttrAccount: "\(bundleIdentifier).\(key)",
                kSecValueData: data,
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            SecItemDelete(query as CFDictionary)
            let status = SecItemAdd(query as CFDictionary, nil)

            return status == errSecSuccess
        }
        return false
    }

    static func retrieve(key: String) -> String? {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return nil }
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: bundleIdentifier,
            kSecAttrAccount: "\(bundleIdentifier).\(key)",
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
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
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: bundleIdentifier,
            kSecAttrAccount: "\(bundleIdentifier).\(key)"
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess {
            printLog("Error removing key from Keychain: \(status)")
        }
    }
}

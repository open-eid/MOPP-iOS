//
//  CryptoDataFile.swift
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

public class CDoc2Settings: NSObject {
    public static let kUseCDoc2Encryption = "kUseCDoc2Encryption"
    public static let kUseCDoc2OnlineEncryption = "kUseCDoc2OnlineEncryption"
    public static let kUseCDoc2SelectedService = "kUseCDoc2SelectedService"
    public static let kUseCDoc2UUID = "kUseCDoc2UUID"
    public static let kUseCDoc2PostURL = "kUseCDoc2PostURL"
    public static let kUseCDoc2FetchURL = "kUseCDoc2FetchURL"

    private static func set(_ key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private static func get(_ key: String) -> Bool {
        return UserDefaults.standard.bool(forKey: key)
    }

    private static func setString(_ key: String, value: String?) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private static func getString(_ key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }

    public class var useEncryption: Bool {
        get { get(kUseCDoc2Encryption) }
        set { set(kUseCDoc2Encryption, value: newValue) }
    }

    public class var useOnlineEncryption: Bool {
        get { get(kUseCDoc2OnlineEncryption) }
        set { set(kUseCDoc2OnlineEncryption, value: newValue) }
    }

    public class var cdoc2SelectedService: String? {
        get { getString(kUseCDoc2SelectedService) }
        set { setString(kUseCDoc2SelectedService, value: newValue) }
    }

    public class var cdoc2UUID: String? {
        get { getString(kUseCDoc2UUID) }
        set { setString(kUseCDoc2UUID, value: newValue) }
    }

    public class var cdoc2PostURL: String? {
        get { getString(kUseCDoc2PostURL) }
        set { setString(kUseCDoc2PostURL, value: newValue) }
    }

    public class var cdoc2FetchURL: String? {
        get { getString(kUseCDoc2FetchURL) }
        set { setString(kUseCDoc2FetchURL, value: newValue) }
    }

    @objc public class func isEncryptionEnabled() -> Bool {
        return get(kUseCDoc2Encryption)
    }

    @objc public class func isOnlineEncryptionEnabled() -> Bool {
        return get(kUseCDoc2OnlineEncryption)
    }

    @objc public class func getSelectedService() -> String? {
        return getString(kUseCDoc2SelectedService)
    }

    @objc public class func getUUID() -> String? {
        return getString(kUseCDoc2UUID)
    }

    @objc public class func getPostURL() -> String? {
        return getString(kUseCDoc2PostURL)
    }

    @objc public class func getFetchURL() -> String? {
        return getString(kUseCDoc2FetchURL)
    }
}

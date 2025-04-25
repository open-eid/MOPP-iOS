//
//  MoppLibManager.swift
//  MoppLib
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

import ExternalAccessory
import Network
import UIKit

public class MoppLibManager: NSObject {
    @objc static public let shared = MoppLibManager()
    public var isConnected: Bool = false
    @objc public var validateOnline = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)

    private override init() {
        super.init()
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
        }
        monitor.start(queue: queue)
    }

    static func moppAppVersion() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "Unknown"
        return "\(version).\(build)"
    }

    static func appLanguage() -> String {
        return UserDefaults.standard.string(forKey: "kMoppLanguage") ?? "N/A"
    }

    @objc static public func userAgent() -> String {
        return userAgent(shouldIncludeDevices: false, isNFCSignature: false)
    }

    @objc static public func userAgent(shouldIncludeDevices: Bool, isNFCSignature: Bool) -> String {
        var appInfo = "riadigidoc/\(moppAppVersion()) (iOS \(UIDevice.current.systemVersion)) Lang: \(appLanguage())"

        if shouldIncludeDevices {
            let connectedDevices = EAAccessoryManager.shared().connectedAccessories.map { device in
                "\(device.manufacturer) \(device.name) (\(device.modelNumber))"
            }
            if !connectedDevices.isEmpty {
                appInfo += " Devices: \(connectedDevices.joined(separator: ", "))"
            }
        }
        
        if isNFCSignature {
            appInfo += " NFC: true"
        }

        return appInfo
    }
}

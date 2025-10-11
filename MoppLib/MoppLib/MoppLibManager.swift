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

@objc public enum SendDiagnostics: Int {
    case Devices
    case NFC
    case None
}

public class MoppLibManager: NSObject {
    @objc static public let shared = MoppLibManager()

    @objc static public var sivaURL: String?
    @objc static public var sivaCert: URL?
    @objc static public var tslURL: String?
    @objc static public var tslCerts: [Data]?
    @objc static public var tsaURL: String?
    @objc static public var tsaCert: URL?
    @objc static public var ocspIssuers: [String: String]?
    @objc static public var certBundle: [Data]?
    @objc public var validateOnline = true

    @objc static public var isDebugMode: Bool {
        UserDefaults.standard.bool(forKey: "isDebugMode")
    }
    @objc static public var isLoggingEnabled: Bool {
        UserDefaults.standard.bool(forKey: "kIsFileLoggingEnabled")
    }

    public var isConnected: Bool = false

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
        return userAgent(sendDiagnostics: .None)
    }

    @objc static public func userAgent(sendDiagnostics: SendDiagnostics) -> String {
        var appInfo = "riadigidoc/\(moppAppVersion()) (iOS \(UIDevice.current.systemVersion)) Lang: \(appLanguage())"

        if sendDiagnostics == .Devices {
            let connectedDevices = EAAccessoryManager.shared().connectedAccessories.map { device in
                "\(device.manufacturer) \(device.name) (\(device.modelNumber))"
            }
            if !connectedDevices.isEmpty {
                appInfo += " Devices: \(connectedDevices.joined(separator: ", "))"
            }
        }
        
        if sendDiagnostics == .NFC {
            appInfo += " NFC: true"
        }

        return appInfo
    }
}

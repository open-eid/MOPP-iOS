//
//  ManualProxy.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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
import MoppLib
import SkSigningLib

public class ManualProxy {

    public static func getManualProxyConfiguration() -> Proxy {
        return Proxy(
            setting: DefaultsHelper.proxySetting,
            host: DefaultsHelper.proxyHost ?? "",
            port: DefaultsHelper.proxyPort,
            username: DefaultsHelper.proxyUsername ?? "",
            password: KeychainUtil.retrieve(key: proxyPasswordKey) ?? "")
    }
    
    public static func getMoppLibProxyConfiguration() -> MoppLibProxyConfiguration {
        let manualProxy = ManualProxy.getManualProxyConfiguration()
        if manualProxy.setting == .systemProxy {
            let systemProxySettings = ProxyUtil.getSystemProxySettings()
            return MoppLibProxyConfiguration(configuration: systemProxySettings.setting.rawValue, host: systemProxySettings.host, port: NSNumber(value: systemProxySettings.port), username: systemProxySettings.username, password: systemProxySettings.password)
        }
        return MoppLibProxyConfiguration(configuration: manualProxy.setting.rawValue, host: manualProxy.host, port: NSNumber(value: manualProxy.port), username: manualProxy.username, password: manualProxy.password)
    }
}

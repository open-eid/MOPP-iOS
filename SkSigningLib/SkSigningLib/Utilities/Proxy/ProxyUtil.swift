//
//  ProxyUtil.swift
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

public enum ProxySetting: String, Codable {
    case noProxy
    case systemProxy
    case manualProxy
}

public class ProxyUtil {
    
    public static func createProxyConfiguration(proxySetting: ProxySetting, proxyHost: String?, proxyPort: Int?, proxyUsername: String?, proxyPassword: String?) -> [AnyHashable: Any]? {
        
        // Use manual proxy settings
        if proxySetting == .manualProxy, let host = proxyHost, let port = proxyPort, !host.isEmpty, port > 0 {
            let proxyConfiguration: [AnyHashable : Any] = [
                String(kCFNetworkProxiesHTTPEnable): 1,
                String(kCFNetworkProxiesHTTPProxy): host,
                String(kCFNetworkProxiesHTTPPort): port,
                String(kCFProxyUsernameKey): proxyUsername ?? "",
                String(kCFProxyPasswordKey): proxyPassword ?? "",
                // Using deprecated keys because HTTPS urls may not be routed through a proxy
                // https://developer.apple.com/forums/thread/19356?answerId=131709022#131709022
                String(kCFStreamPropertyHTTPSProxyHost): host,
                String(kCFStreamPropertyHTTPSProxyPort): port
            ]
            
            return proxyConfiguration
        }
        // Check if system proxy settings exist. iOS automatically handles proxy configuration with system settings
        else if proxySetting == .systemProxy {
            let proxySettings = ProxyUtil.getSystemProxySettings()
            if !proxySettings.host.isEmpty && proxySettings.port > 0 {
                ProxyUtil.updateSystemProxySettings()
                return nil
            }
        }

        return [
            String(kCFNetworkProxiesHTTPEnable): 0
        ]
    }
    
    public static func getProxyAuthorizationHeader(username: String, password: String) -> String? {
        let credentials = "\(username):\(password)"

        if let credentialsData = credentials.data(using: .utf8) {
            return credentialsData.base64EncodedString(options: [])
        }
        
        return nil
    }
    
    public static func setProxyAuthorizationHeader(request: inout URLRequest, urlSessionConfiguration: URLSessionConfiguration, manualProxyConf: Proxy) {
        if let connectionProxyDictionary = urlSessionConfiguration.connectionProxyDictionary,
            !connectionProxyDictionary.isEmpty,
            !manualProxyConf.host.isEmpty,
           let proxyHeader = ProxyUtil.getProxyAuthorizationHeader(username: manualProxyConf.username, password: manualProxyConf.password) {

            request.setValue("Basic \(proxyHeader)", forHTTPHeaderField: "Proxy-Authorization")
        }
    }
    
    public static func configureURLSessionWithProxy(urlSessionConfiguration: inout URLSessionConfiguration, manualProxyConf: Proxy) {
        let proxyConfiguration = ProxyUtil.createProxyConfiguration(
            proxySetting: manualProxyConf.setting,
            proxyHost: manualProxyConf.host, proxyPort: manualProxyConf.port, proxyUsername: manualProxyConf.username, proxyPassword: manualProxyConf.password)
        
        if let proxyConf = proxyConfiguration {
            urlSessionConfiguration.connectionProxyDictionary = proxyConf
        }
    }
    
    public static func getSystemProxySettings() -> Proxy {
        guard let proxySettingsUnmanaged = CFNetworkCopySystemProxySettings() else {
            return Proxy(setting: .systemProxy, host: "", port: 80, username: "", password: "")
        }
        let proxySettings = proxySettingsUnmanaged.takeRetainedValue() as? [AnyHashable : Any]
        if let systemHost = proxySettings?[kCFNetworkProxiesHTTPProxy] as? String, let systemPort = proxySettings?[kCFNetworkProxiesHTTPPort] as? Int, !systemHost.isEmpty && systemPort > 0 {
            return Proxy(setting: .systemProxy, host: systemHost, port: systemPort, username: "", password: "")
        }
        
        return Proxy(setting: .systemProxy, host: "", port: 80, username: "", password: "")
    }
    
    public static func getProxySetting() -> ProxySetting {
        let defaults = UserDefaults.standard
        return ProxySetting(rawValue: defaults.value(forKey: "kProxySetting") as? String ?? "") ?? .noProxy
    }
    
    public static func updateSystemProxySettings() {
        let proxySettings = ProxyUtil.getSystemProxySettings()
        if !proxySettings.host.isEmpty && proxySettings.port > 0 {
            let defaults = UserDefaults.standard
            defaults.set(proxySettings.setting.rawValue, forKey: "kProxySetting")
            defaults.set(proxySettings.host, forKey: "kProxyHost")
            defaults.set(proxySettings.port, forKey: "kProxyPort")
            defaults.set("", forKey: "kProxyUsername")
        }
    }
}

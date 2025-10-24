//
//  SettingsConfiguration.swift
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

/*
 * Settings Configuration manager that loads and initializes configuration.
 *
 * For initial application startup, configuration is loaded from central configuration service.
 * If loading from central configuration service fails, then configuration is loaded from cache (if exists).
 * If loading from cache fails or cache does not yet exist, then default configuration is loaded.
 * Default configuration is packaged to IPA.
 *
 * Loaded configuration is then cached to the devices drive. Configuration consists of configuration json,
 * it's signature and public key. Along with named configuration files, defaultConfiguration.json file contains
 * default configuration values. This configuration value includes <lastUpdateCheckDate>
 * which is updated each time central configuration is downloaded, and parameter <updateDate>
 * which is updated each time downloaded central configuration is actually loaded for usage.
 *
 * During each application start-up, cached configuration last checked update date (lastUpdateCheckDate) is compared
 * to current date, and if the difference in days exceeds <updateInterval (defaults to 4)>, then
 * configuration is downloaded from central configuration service. If downloaded central configuration
 * differs from cached configuration, then central configuration is loaded for use and cached
 * configuration is updated, else cached version is used.
 */

import SkSigningLib

class SettingsConfiguration: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {

    static let isCentralConfigurationLoaded = Notification.Name("isCentralConfigurationLoaded")

    public func getCentralConfiguration() -> Void {

        if let cachedData = getConfigurationFromCache(forKey: "config") as? String {
            var decodedData: MOPPConfiguration? = nil
            do {
                decodedData = try MOPPConfiguration(json: cachedData)
            } catch {
                printLog("Unable to decode data: \(error.localizedDescription)")
                loadLocalConfiguration()
            }

            if let decodedConfiguration = decodedData, decodedConfiguration.METAINF.SERIAL >= getDefaultMoppConfiguration().VERSIONSERIAL {
                loadCachedConfiguration()
                if isCentralUpdateRequired() {
                    DispatchQueue.global(qos: .background).async {
                        self.loadCentralConfiguration()
                    }
                }
                if isInitialSetup() {
                    self.loadCentralConfiguration()
                }
            } else if let decodedConfiguration = decodedData, decodedConfiguration.METAINF.SERIAL < getDefaultMoppConfiguration().VERSIONSERIAL {
                loadLocalConfiguration()
                if isCentralUpdateRequired() {
                    DispatchQueue.global(qos: .background).async {
                        self.loadCentralConfiguration()
                    }
                }
                if isInitialSetup() {
                    self.loadCentralConfiguration()
                }
            } else {
                loadLocalConfiguration()
            }
        }

        else {
            loadLocalConfiguration()
            if isCentralUpdateRequired() {
                DispatchQueue.global(qos: .background).async {
                    self.loadCentralConfiguration()
                }
            }
        }
    }
    
    func isCentralUpdateRequired() -> Bool {
        return isDateAfterInterval(updateDate: SettingsConfiguration().getConfigurationFromCache(forKey: "lastUpdateCheckDate") as? Date ?? self.getConfigurationFromCache(forKey: "updateDate") as! Date, interval: getDefaultMoppConfiguration().UPDATEINTERVAL)
    }


    internal func loadLocalConfiguration() {
        do {
            let localConfigData = try String(contentsOfFile: Bundle.main.path(forResource: "config", ofType: "json")!)
            let localSignature = try String(contentsOfFile: Bundle.main.path(forResource: "signature", ofType: "ecc")!)
            let decodedData = try MOPPConfiguration(json: localConfigData)
            setAllConfigurationToCache(configData: localConfigData, signature: localSignature, initialUpdateDate: MoppDateFormatter().stringToDate(dateString: getDefaultMoppConfiguration().UPDATEDATE), versionSerial: decodedData.METAINF.SERIAL)
            setConfigurationToCache("", forKey: "lastUpdateDateCheck")

            Configuration.moppConfig = decodedData
            setupMoppConfiguration(configuration: decodedData)
            setupMoppLDAPConfiguration(configuration: decodedData)
        } catch {
            printLog("Unable to read file: \(error.localizedDescription)")
            fatalError("Unable to read default file(s)")
        }
    }

    internal func loadCachedConfiguration() {
        do {
            let cachedConfigData = getConfigurationFromCache(forKey: "config") as! String
            let localPublicKey = try String(contentsOfFile: Bundle.main.path(forResource: "publicKey", ofType: "ecpub")!)
            let cachedSignature = getConfigurationFromCache(forKey: "signature") as! String

            _ = try SignatureVerifier.isSignatureCorrect(configData: cachedConfigData, publicKey: localPublicKey, signature: cachedSignature)

            let decodedData = try MOPPConfiguration(json: cachedConfigData)
            Configuration.moppConfig = decodedData
            setupMoppConfiguration(configuration: decodedData)
            setupMoppLDAPConfiguration(configuration: decodedData)
        } catch {
            printLog("Unable to read file: \(error.localizedDescription)")
            loadLocalConfiguration()
        }
    }
    
    private func setupCentralConfiguration(centralConfig: String, centralSignature: String, decodedData: MOPPConfiguration) {
        setAllConfigurationToCache(configData: centralConfig, signature: centralSignature, versionSerial: decodedData.METAINF.SERIAL)
        Configuration.moppConfig = decodedData
        setupMoppConfiguration(configuration: decodedData)
        setupMoppLDAPConfiguration(configuration: decodedData)
        NotificationCenter.default.post(name: SettingsConfiguration.isCentralConfigurationLoaded, object: nil, userInfo: ["isLoaded": true])
        setConfigurationToCache(true, forKey: "isCentralConfigurationLoaded")
    }
    
    private func handleCacheConfiguration() -> Void {
        self.setConfigurationToCache(Date(), forKey: "lastUpdateCheckDate")
        self.loadCachedConfiguration()
        NotificationCenter.default.post(name: SettingsConfiguration.isCentralConfigurationLoaded, object: nil, userInfo: ["isLoaded": false])
    }

    internal func loadCentralConfiguration(completionHandler: @escaping (Error) -> () = { _ in }) {
        do {
            let cachedSignature = getConfigurationFromCache(forKey: "signature") as? String
            let localPublicKey = try String(contentsOfFile: Bundle.main.path(forResource: "publicKey", ofType: "ecpub")!)

            if isInitialSetup() {
                setConfigurationToCache(true, forKey: "isCentralConfigurationLoaded")
                loadCachedConfiguration()
            }
            
            getFetchedData(fromUrl: "\(getDefaultMoppConfiguration().CENTRALCONFIGURATIONSERVICEURL)/config.ecc") { (centralSignature, signatureError) in
                if let error = signatureError {
                    printLog(error.localizedDescription)
                    return completionHandler(error)
                }
                guard let centralSignature = centralSignature else {
                    self.handleCacheConfiguration()
                    return
                }
                if SignatureVerifier.hasSignatureChanged(oldSignature: cachedSignature!, newSignature: centralSignature) {
                    self.getFetchedData(fromUrl: "\(self.getDefaultMoppConfiguration().CENTRALCONFIGURATIONSERVICEURL)/config.json") { (centralConfig, configError) in
                        if let confError = configError {
                            printLog(confError.localizedDescription)
                            self.handleCacheConfiguration()
                        }
                        guard let centralConfig = centralConfig else {
                            self.handleCacheConfiguration()
                            return
                        }
                        do {
                            _ = try SignatureVerifier.isSignatureCorrect(configData: centralConfig, publicKey: localPublicKey, signature: centralSignature)
                            let decodedData = try MOPPConfiguration(json: centralConfig)
                            self.setupCentralConfiguration(centralConfig: centralConfig, centralSignature: centralSignature, decodedData: decodedData)
                        }
                        catch {
                            self.handleCacheConfiguration()
                        }
                    }
                } else {
                    self.handleCacheConfiguration()
                }
            }
        } catch {
            printLog("Unable to load data: \(error.localizedDescription)")
            loadCachedConfiguration()
        }
    }

    internal func getDefaultMoppConfiguration() -> DefaultMoppConfiguration {
        do {
            let defaultConfigData = try String(contentsOfFile: Bundle.main.path(forResource: "defaultConfiguration", ofType: "json")!)
            return try DefaultMoppConfiguration(json: defaultConfigData)
        } catch {
            printLog("Unable to decode data: \(error.localizedDescription)")
            fatalError("Unable to decode default MOPP configuration!")
        }
    }

    private func fetchDataFromCentralConfiguration(fromUrl: String, completionHandler: @escaping (String?, Error?) -> Void) -> Void {
        guard let url = URL(string: fromUrl) else { return }
        
        let manualProxyConf = ManualProxy.getManualProxyConfiguration()
        
        var urlSessionConfiguration = URLSessionConfiguration.default
        ProxySettingsUtil.updateSystemProxySettings()
        ProxyUtil.configureURLSessionWithProxy(urlSessionConfiguration: &urlSessionConfiguration, manualProxyConf: manualProxyConf)
        urlSessionConfiguration.timeoutIntervalForResource = 5.0
        urlSessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let urlSession = URLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: nil)
        
        let userAgent = MoppLibManager.userAgent()
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        ProxyUtil.setProxyAuthorizationHeader(request: &request, urlSessionConfiguration: urlSessionConfiguration, manualProxyConf: manualProxyConf)

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            
            if let err = error as? NSError {
                if err.code == -1009 || err.code == -1003 || err.code == 310 {
                    return completionHandler(nil, DiagnosticError.noInternetConnection)
                } else {
                    return completionHandler(nil, err)
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return completionHandler(nil, error)
            }
            
            if error != nil {
                printLog("Settings configuration - \(error?.localizedDescription ?? "Error not available")")
                return completionHandler(nil, error)
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                printLog("Settings configuration - HTTP Status Code: \(httpResponse.statusCode). \(error?.localizedDescription ?? "Error not available")")
                return completionHandler(nil, NSError(domain: "SettingsConfiguration", code: 0))
            }
            

            guard let data = data else { return }

            guard let dataAsString = String(bytes: data, encoding: String.Encoding.utf8) else { return }

            completionHandler(dataAsString, error)

        })

        task.resume()
    }

    private func getFetchedData(fromUrl url: String, completionHandler: @escaping (String?, Error?) -> Void) {
        fetchDataFromCentralConfiguration(fromUrl: url) { (data, error) in
            if (error != nil) {
                printLog(error!.localizedDescription)
                return completionHandler(nil, error)
            }
            guard let data = data else { return }
            
            completionHandler(data, error)
        }
    }


    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if getDefaultMoppConfiguration().CENTRALCONFIGURATIONSERVICEURL.contains("test") {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
        else {
            completionHandler(.performDefaultHandling, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
    }
    
    internal func isInitialSetup() -> Bool {
        return getConfigurationFromCache(forKey: "isCentralConfigurationLoaded") == nil || getConfigurationFromCache(forKey: "isCentralConfigurationLoaded") as! Bool == false ? true : false
    }

    internal func getConfigurationFromCache(forKey: String) -> Any? {
        return UserDefaults.standard.value(forKey: forKey)
    }

    private func setConfigurationToCache<T: Equatable>(_ data: T, forKey: String) -> Void {
        let defaults = UserDefaults.standard
        defaults.set(data, forKey: forKey)
        defaults.synchronize()
    }

    private func setAllConfigurationToCache(configData: String, signature: String, initialUpdateDate: Date? = nil, versionSerial: Int) -> Void {

        let updateDate: Date = Date()

        self.setConfigurationToCache(configData, forKey: "config")
        self.setConfigurationToCache(signature, forKey: "signature")
        initialUpdateDate != nil ? self.setConfigurationToCache(initialUpdateDate, forKey: "lastUpdateCheckDate") : self.setConfigurationToCache(updateDate, forKey: "lastUpdateCheckDate")
        initialUpdateDate != nil ? self.setConfigurationToCache(initialUpdateDate, forKey: "updateDate") : self.setConfigurationToCache(updateDate, forKey: "updateDate")
        self.setConfigurationToCache(versionSerial, forKey: "versionSerial")
    }

    private func setupMoppConfiguration(configuration: MOPPConfiguration) -> Void {
        MoppLibManager.sivaURL = configuration.SIVAURL
        if let fileName = DefaultsHelper.sivaCertFileName {
            MoppLibManager.sivaCert = CertUtil.getCertFile(folder: "siva-cert", fileName: fileName)
        }
        MoppLibManager.tslURL = configuration.TSLURL
        MoppLibManager.tslCerts = configuration.TSLCERTS
        MoppLibManager.tsaURL = configuration.TSAURL
        if let fileName = DefaultsHelper.tsaCertFileName {
            MoppLibManager.tsaCert = CertUtil.getCertFile(folder: "tsa-cert", fileName: fileName)
        }
        MoppLibManager.ocspIssuers = configuration.OCSPISSUERS
        MoppLibManager.certBundle = configuration.CERTBUNDLE
    }

    private func isDateAfterInterval(updateDate: Date, interval: Int) -> Bool {
        return Calendar.current.date(byAdding: .day, value: interval, to: updateDate)! < Date()
    }

    private func setupMoppLDAPConfiguration(configuration: MOPPConfiguration) {
        MoppLdapConfiguration.ldapPersonURLS = configuration.LDAPPERSONURLS ?? [configuration.LDAPPERSONURL]
        MoppLdapConfiguration.ldapCorpURL = configuration.LDAPCORPURL

        guard !configuration.LDAPCERTS.isEmpty else { printLog("No LDAP certs found (central configuration)"); return }
        guard let ldapCertsPath = MoppLdapConfiguration.ldapCertsPath else { printLog("No LDAP certs path found"); return }

        let ldapCertsDirectory = (ldapCertsPath as NSString).deletingLastPathComponent
        if !MoppFileManager.shared.directoryExists(ldapCertsDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: ldapCertsDirectory, withIntermediateDirectories: true)
            } catch {
                printLog("Error creating LDAP certificates directory: \(error.localizedDescription)")
                return
            }
        }
        if !FileManager.default.fileExists(atPath: ldapCertsPath) {
            guard FileManager.default.createFile(atPath: ldapCertsPath, contents: nil) else {
                printLog("Failed to create file: \(ldapCertsPath)")
                return
            }
        }
        guard let fileHandle = FileHandle(forWritingAtPath: ldapCertsPath) else {
            printLog("Error writing to LDAP certs file")
            return
        }
        defer { fileHandle.closeFile() }
        let certStart = "-----BEGIN CERTIFICATE-----\n".data(using: .utf8)!
        let certEnd = "\n-----END CERTIFICATE-----\n".data(using: .utf8)!
        for (index, cert) in configuration.LDAPCERTS.enumerated() {
            guard !cert.isEmpty else { continue }
            printLog("Writing LDAP cert \(index + 1)")
            fileHandle.write(certStart)
            fileHandle.write(cert.base64EncodedData(options: .lineLength64Characters))
            fileHandle.write(certEnd)
            printLog("LDAP certificate file written")
        }
    }
}

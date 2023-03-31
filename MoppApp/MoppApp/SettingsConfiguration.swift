//
//  SettingsConfiguration.swift
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

import SwiftyRSA

class SettingsConfiguration: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {

    static let isCentralConfigurationLoaded = Notification.Name("isCentralConfigurationLoaded")

    public func getCentralConfiguration() -> Void {

        if let cachedData = getConfigurationFromCache(forKey: "config") as? String {
            var decodedData: MOPPConfiguration? = nil
            do {
                decodedData = try MoppConfigurationDecoder().decodeMoppConfiguration(configData: cachedData)
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
            let localSignature = try String(contentsOfFile: Bundle.main.path(forResource: "signature", ofType: "rsa")!)
            let decodedData = try MoppConfigurationDecoder().decodeMoppConfiguration(configData: localConfigData)
            setAllConfigurationToCache(configData: localConfigData, signature: localSignature, initialUpdateDate: MoppDateFormatter().stringToDate(dateString: getDefaultMoppConfiguration().UPDATEDATE), versionSerial: decodedData.METAINF.SERIAL)
            setConfigurationToCache("", forKey: "lastUpdateDateCheck")
            
            setupMoppConfiguration(sivaUrl: decodedData.SIVAURL, tslUrl: decodedData.TSLURL, tslCerts: decodedData.TSLCERTS, tsaUrl: decodedData.TSAURL, ocspIssuers: decodedData.OCSPISSUERS, certBundle: decodedData.CERTBUNDLE)
            setMoppConfiguration(configuration: decodedData)
            
            setupMoppLDAPConfiguration(ldapPersonUrl: decodedData.LDAPPERSONURL, ldapCorpUrl: decodedData.LDAPCORPURL)
        } catch {
            printLog("Unable to read file: \(error.localizedDescription)")
            fatalError("Unable to read default file(s)")
        }
    }

    internal func loadCachedConfiguration() {
        do {
            let cachedConfigData = getConfigurationFromCache(forKey: "config") as! String
            let localPublicKey = try String(contentsOfFile: Bundle.main.path(forResource: "publicKey", ofType: "pub")!)
            let cachedSignature = getConfigurationFromCache(forKey: "signature") as! String

            _ = try SignatureVerifier().isSignatureCorrect(configData: trim(text: cachedConfigData)!, publicKey: localPublicKey, signature: cachedSignature)

            let decodedData = try MoppConfigurationDecoder().decodeMoppConfiguration(configData: cachedConfigData)
            setupMoppConfiguration(sivaUrl: decodedData.SIVAURL, tslUrl: decodedData.TSLURL, tslCerts: decodedData.TSLCERTS, tsaUrl: decodedData.TSAURL, ocspIssuers: decodedData.OCSPISSUERS, certBundle: decodedData.CERTBUNDLE)
            setMoppConfiguration(configuration: decodedData)
            
            setupMoppLDAPConfiguration(ldapPersonUrl: decodedData.LDAPPERSONURL, ldapCorpUrl: decodedData.LDAPCORPURL)

        } catch {
            printLog("Unable to read file: \(error.localizedDescription)")
            loadLocalConfiguration()
        }
    }
    
    private func setupCentralConfiguration(centralConfig: String, centralSignature: String, decodedData: MOPPConfiguration) {
        setAllConfigurationToCache(configData: centralConfig, signature: centralSignature, versionSerial: decodedData.METAINF.SERIAL)
        setMoppConfiguration(configuration: decodedData)
        setupMoppConfiguration(sivaUrl: decodedData.SIVAURL, tslUrl: decodedData.TSLURL, tslCerts: decodedData.TSLCERTS, tsaUrl: decodedData.TSAURL, ocspIssuers: decodedData.OCSPISSUERS, certBundle: decodedData.CERTBUNDLE)
        NotificationCenter.default.post(name: SettingsConfiguration.isCentralConfigurationLoaded, object: nil, userInfo: ["isLoaded": true])
        setConfigurationToCache(true, forKey: "isCentralConfigurationLoaded")
        reloadDigiDocConf()
    }
    
    private func handleCacheConfiguration() -> Void {
        self.setConfigurationToCache(Date(), forKey: "lastUpdateCheckDate")
        self.loadCachedConfiguration()
        NotificationCenter.default.post(name: SettingsConfiguration.isCentralConfigurationLoaded, object: nil, userInfo: ["isLoaded": false])
    }

    internal func loadCentralConfiguration(completionHandler: @escaping (Error) -> () = { _ in }) {
        do {
            let cachedSignature = getConfigurationFromCache(forKey: "signature") as? String
            let localPublicKey = try String(contentsOfFile: Bundle.main.path(forResource: "publicKey", ofType: "pub")!)
            
            if isInitialSetup() {
                setConfigurationToCache(true, forKey: "isCentralConfigurationLoaded")
                loadCachedConfiguration()
            }
            
            getFetchedData(fromUrl: "\(getDefaultMoppConfiguration().CENTRALCONFIGURATIONSERVICEURL)/config.rsa") { (centralSignature, signatureError) in
                if let error = signatureError {
                    printLog(error.localizedDescription)
                    completionHandler(error)
                }
                guard let centralSignature = centralSignature else {
                    self.handleCacheConfiguration()
                    return
                }
                if SignatureVerifier().hasSignatureChanged(oldSignature: cachedSignature!, newSignature: centralSignature) {
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
                            _ = try SignatureVerifier().isSignatureCorrect(configData: self.trim(text: centralConfig)!, publicKey: localPublicKey, signature: centralSignature)
                            let decodedData = try MoppConfigurationDecoder().decodeMoppConfiguration(configData: centralConfig)
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
            return try MoppConfigurationDecoder().decodeDefaultMoppConfiguration(configData: defaultConfigData)
        } catch {
            printLog("Unable to decode data: \(error.localizedDescription)")
            fatalError("Unable to decode default MOPP configuration!")
        }
    }

    private func fetchDataFromCentralConfiguration(fromUrl: String, completionHandler: @escaping (String?, Error?) -> Void) -> Void {
        guard let url = URL(string: fromUrl) else { return }

        let urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.timeoutIntervalForResource = 5.0
        urlSessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let urlSession = URLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: nil)
        
        let userAgent = MoppLibManager.sharedInstance().userAgent()
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            
            if let err = error as? NSError {
                if err.code == -1009 {
                    completionHandler(nil, DiagnosticError.noInternetConnection)
                } else {
                    completionHandler(nil, err)
                }
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
                completionHandler(nil, error)
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

    private func setMoppConfiguration(configuration: MOPPConfiguration) -> Void {
        Configuration.moppConfig = configuration
    }

    private func setupMoppConfiguration(sivaUrl: String, tslUrl: String, tslCerts: Array<String>, tsaUrl: String, ocspIssuers: [String: String], certBundle: Array<String>) -> Void {
        MoppConfiguration.sivaUrl = sivaUrl
        MoppConfiguration.tslUrl = tslUrl
        MoppConfiguration.tslCerts = tslCerts
        MoppConfiguration.tsaUrl = tsaUrl
        MoppConfiguration.ocspIssuers = ocspIssuers
        MoppConfiguration.certBundle = certBundle
        MoppConfiguration.tsaCert = TSACertUtil.certificateString()
    }

    private func setupMoppLDAPConfiguration(ldapPersonUrl: String, ldapCorpUrl: String) {
        MoppLDAPConfiguration.ldapPersonUrl = ldapPersonUrl
        MoppLDAPConfiguration.ldapCorpUrl = ldapCorpUrl
    }

    private func isDateAfterInterval(updateDate: Date, interval: Int) -> Bool {
        return Calendar.current.date(byAdding: .day, value: interval, to: updateDate)! < Date()
    }

    private func trim(text: String?) -> String? {
        return text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    private func reloadDigiDocConf() {
        #if USE_TEST_DDS
            let useTestDDS = true
        #else
            let useTestDDS = false
        #endif

        MoppLibManager.sharedInstance()?.setup(success: {
            printLog("Successfully reloaded DigiDocConf")
        }, andFailure: { error in
            printLog("Failed to reload DigiDocConf")
            fatalError("Failed to reload DigiDocConf")
        }, usingTestDigiDocService: useTestDDS, andTSUrl: DefaultsHelper.timestampUrl ?? MoppConfiguration.getMoppLibConfiguration().tsaurl,
           withMoppConfiguration: MoppConfiguration.getMoppLibConfiguration())
    }
}

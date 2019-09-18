//
//  SettingsConfiguration.swift
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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
 * During each application start-up, cached configuration update date (updateDate) is compared
 * to current date, and if the difference in days exceeds <updateInterval (defaults to 7)>, then
 * configuration is downloaded from central configuration service. If downloaded central configuration
 * differs from cached configuration, then central configuration is loaded for use and cached
 * configuration is updated, else cached version is used.
 */

import SwiftyRSA

class SettingsConfiguration: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    public func getCentralConfiguration() -> Void {
        
        if let cachedData = getConfigurationFromCache(forKey: "config") as? String {
            var decodedData: MOPPConfiguration? = nil
            do {
                decodedData = try Decoding().decodeMoppConfiguration(configData: cachedData)
            } catch {
                MSLog("Unable to decode data: ", error.localizedDescription)
                loadLocalConfiguration()
            }
            
            if decodedData!.METAINF.SERIAL >= getDefaultMoppConfiguration().VERSIONSERIAL {
                loadCachedConfiguration()
                if self.isDateAfterInterval(updateDate: self.getConfigurationFromCache(forKey: "updateDate") as! Date, interval: getDefaultMoppConfiguration().UPDATEINTERVAL) {
                    DispatchQueue.global(qos: .background).async {
                        self.loadCentralConfiguration()
                    }
                }
            } else if decodedData!.METAINF.SERIAL < getDefaultMoppConfiguration().VERSIONSERIAL {
                loadLocalConfiguration()
                if self.isDateAfterInterval(updateDate: self.getConfigurationFromCache(forKey: "updateDate") as! Date, interval: getDefaultMoppConfiguration().UPDATEINTERVAL) {
                    DispatchQueue.global(qos: .background).async {
                        self.loadCentralConfiguration()
                    }
                }
            }
        }
            
        else {
            loadLocalConfiguration()
            if self.isDateAfterInterval(updateDate: self.getConfigurationFromCache(forKey: "updateDate") as! Date, interval: getDefaultMoppConfiguration().UPDATEINTERVAL) {
                DispatchQueue.global(qos: .background).async {
                    self.loadCentralConfiguration()
                }
            }
        }
    }
    
    
    internal func loadLocalConfiguration() {
        do {
            let localConfigData = try String(contentsOfFile: Bundle.main.path(forResource: "config", ofType: "json")!)
            let localSignature = try String(contentsOfFile: Bundle.main.path(forResource: "signature", ofType: "rsa")!)
            let decodedData = try Decoding().decodeMoppConfiguration(configData: localConfigData)
            setAllConfigurationToCache(configData: localConfigData, signature: localSignature, versionSerial: decodedData.METAINF.SERIAL)
            setConfigurationToCache("", forKey: "lastUpdateDateCheck")
            
            setupMoppConfiguration(sivaUrl: decodedData.SIVAURL, tslUrl: decodedData.TSLURL, tslCerts: decodedData.TSLCERTS, tsaUrl: decodedData.TSAURL, ocspIssuers: decodedData.OCSPISSUERS)
            setupMoppLDAPConfiguration(ldapPersonUrl: decodedData.LDAPPERSONURL, ldapCorpUrl: decodedData.LDAPCORPURL)
            
            setMoppConfiguration(configuration: decodedData)
            
        } catch {
            MSLog("Unable to read file: ", error.localizedDescription)
            fatalError("Unable to read default file(s)")
        }
    }
    
    internal func loadCachedConfiguration() {
        do {
            let cachedConfigData = getConfigurationFromCache(forKey: "config") as! String
            let localPublicKey = try String(contentsOfFile: Bundle.main.path(forResource: "publicKey", ofType: "pub")!)
            let cachedSignature = getConfigurationFromCache(forKey: "signature") as! String
            
            _ = try SignatureVerifier().isSignatureCorrect(configData: trim(text: cachedConfigData)!, publicKey: localPublicKey, signature: cachedSignature)
            
            let decodedData = try Decoding().decodeMoppConfiguration(configData: cachedConfigData)
            setupMoppConfiguration(sivaUrl: decodedData.SIVAURL, tslUrl: decodedData.TSLURL, tslCerts: decodedData.TSLCERTS, tsaUrl: decodedData.TSAURL, ocspIssuers: decodedData.OCSPISSUERS)
            setupMoppLDAPConfiguration(ldapPersonUrl: decodedData.LDAPPERSONURL, ldapCorpUrl: decodedData.LDAPCORPURL)
            
            setMoppConfiguration(configuration: decodedData)
            
        } catch {
            MSLog("Unable to read file: ", error.localizedDescription)
            loadLocalConfiguration()
        }
    }
    
    internal func loadCentralConfiguration() {
        do {
            let centralSignature = try self.getFetchedData(fromUrl: "\(getDefaultMoppConfiguration().CENTRALCONFIGURATIONSERVICEURL)/config.rsa")
            let cachedSignature = getConfigurationFromCache(forKey: "signature") as? String
            
            if SignatureVerifier().hasSignatureChanged(oldSignature: cachedSignature!, newSignature: centralSignature) {
                let centralConfigData = try self.getFetchedData(fromUrl: "\(getDefaultMoppConfiguration().CENTRALCONFIGURATIONSERVICEURL)/config.json")
                let localPublicKey = try String(contentsOfFile: Bundle.main.path(forResource: "publicKey", ofType: "pub")!)
                
                _ = try SignatureVerifier().isSignatureCorrect(configData: trim(text: centralConfigData)!, publicKey: localPublicKey, signature: centralSignature)
                let decodedData = try Decoding().decodeMoppConfiguration(configData: centralConfigData)
                setAllConfigurationToCache(configData: centralConfigData, signature: centralSignature, versionSerial: decodedData.METAINF.SERIAL)
                
                setMoppConfiguration(configuration: decodedData)
                
                reloadDigiDocConf(tsUrl: decodedData.TSAURL)
                
            } else {
                setConfigurationToCache(Date(), forKey: "lastUpdateCheckDate")
                loadCachedConfiguration()
            }
            
        } catch {
            MSLog("Unable to load data: ", error.localizedDescription)
            loadCachedConfiguration()
        }
        
    }
    
    private func getDefaultMoppConfiguration() -> DefaultMoppConfiguration {
        do {
            let defaultConfigData = try String(contentsOfFile: Bundle.main.path(forResource: "defaultConfiguration", ofType: "json")!)
            return try Decoding().decodeDefaultMoppConfiguration(configData: defaultConfigData)
        } catch {
            MSLog("Unable to decode data: ", error.localizedDescription)
            fatalError("Unable to decode default MOPP configuration!")
        }
    }
    
    private func fetchDataFromCentralConfiguration(fromUrl: String, completionHandler: @escaping (String?, Error?) -> Void) -> Void {
        guard let url = URL(string: fromUrl) else { return }
        
        let urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.timeoutIntervalForResource = 5.0
        let urlSession = URLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: nil)
        
        let task = urlSession.dataTask(with: url, completionHandler: { data, response, error in
            
            guard let data = data else { return }
            
            guard let dataAsString = String(bytes: data, encoding: String.Encoding.utf8) else { return }
            
            if error != nil {
                MSLog(error!.localizedDescription)
            }
            
            completionHandler(dataAsString, error)
            
        })
        
        task.resume()
    }
    
    private func getFetchedData(fromUrl: String) throws -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var configData: String = "";
        var networkError: Error?
        fetchDataFromCentralConfiguration(fromUrl: fromUrl) { (data, error) in
            if (error != nil) {
                networkError = error!
            }
            guard let data = data else { return }
            configData = data
            semaphore.signal()
        }
        semaphore.wait()
        
        if networkError != nil {
            throw networkError!
        }
        
        return configData
    }
    
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if getDefaultMoppConfiguration().CENTRALCONFIGURATIONSERVICEURL.contains("test") {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
        else {
            completionHandler(.performDefaultHandling, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
    }
    
    internal func getConfigurationFromCache(forKey: String) -> Any? {
        return UserDefaults.standard.value(forKey: forKey)
    }
    
    private func setConfigurationToCache<T: Equatable>(_ data: T, forKey: String) -> Void {
        let defaults = UserDefaults.standard
        defaults.set(data, forKey: forKey)
        defaults.synchronize()
    }
    
    private func setAllConfigurationToCache(configData: String, signature: String, versionSerial: Int) -> Void {
        
        let updateDate: Date = Date()
        
        self.setConfigurationToCache(configData, forKey: "config")
        self.setConfigurationToCache(signature, forKey: "signature")
        self.setConfigurationToCache(updateDate, forKey: "lastUpdateCheckDate")
        self.setConfigurationToCache(updateDate, forKey: "updateDate")
        self.setConfigurationToCache(versionSerial, forKey: "versionSerial")
    }
    
    private func setMoppConfiguration(configuration: MOPPConfiguration) -> Void {
        Configuration.moppConfig = configuration
    }
    
    private func setupMoppConfiguration(sivaUrl: String, tslUrl: String, tslCerts: Array<String>, tsaUrl: String, ocspIssuers: [String: String]) -> Void {
        MoppConfiguration.sivaUrl = sivaUrl
        MoppConfiguration.tslUrl = tslUrl
        MoppConfiguration.tslCerts = tslCerts
        MoppConfiguration.tsaUrl = tsaUrl
        MoppConfiguration.ocspIssuers = ocspIssuers
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
    
    private func reloadDigiDocConf(tsUrl: String) {
        #if USE_TEST_DDS
            let useTestDDS = true
        #else
            let useTestDDS = false
        #endif
        
        MoppLibManager.sharedInstance()?.setup(success: {
            MSLog("Successfully reloaded DigiDocConf")
        }, andFailure: { error in
            MSLog("Failed to reload DigiDocConf")
            fatalError("Failed to reload DigiDocConf")
        }, usingTestDigiDocService: useTestDDS, andTSUrl: tsUrl,
           withMoppConfiguration: MoppConfiguration.getMoppLibConfiguration())
    }
}

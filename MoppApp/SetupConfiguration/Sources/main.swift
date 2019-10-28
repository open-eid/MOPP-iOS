#!/usr/bin/swift sh
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

import Foundation
import SwCrypt // ./SetupConfiguration/Sources/SwCrypt/

class SettingsConfiguration: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    let configBaseUrl: String = CommandLine.arguments[1] ?? "https://id.eesti.ee"
    let configUpdateInterval: Int = Int(CommandLine.arguments[2]) ?? 7
    let configTslUrl: String = CommandLine.arguments[3] ?? "https://ec.europa.eu/tools/lotl/eu-lotl.xml"
    
    let configCertName: String = "test-cert.cer"
    
    internal func setupConfiguration() {

        var configData: String?
        var publicKey: String?
        var signature: String?
        
        print("1 / 4 - Downloading configuration data...")
        
        do {
            configData = try self.getFetchedData(fromUrl: "\(configBaseUrl)/config.json")
            publicKey = try self.getFetchedData(fromUrl: "\(configBaseUrl)/config.pub")
            signature = try self.getFetchedData(fromUrl: "\(configBaseUrl)/config.rsa")
        } catch {
            fatalError("Unable to get data from central configuration \(error.localizedDescription)")
        }
        
        print("2 / 4 - Verifing configuration data...")
        
        verifySignature(configData: configData!, publicKey: publicKey!, signature: signature!)
        
        print("3 / 4 - Creating default configuration file...")
        
        let defaultConfiguration: String?
        
        do {
            let decodedData = try decodeMoppConfiguration(configData: configData!)
            defaultConfiguration = createConfigurationFile(versionSerial: decodedData.METAINF.SERIAL)
        } catch {
            fatalError("Unable to decode data: \(error.localizedDescription)")
        }
        
        print("4 / 4 - Saving and moving files to project directory...")
        
        saveAndMoveConfigurationFiles(configData: configData!, publicKey: publicKey!, signature: signature!, defaultConfiguration: defaultConfiguration!)
        
        print("Default configuration initialized successfully!")
    }
    
    /* Get data from Central Configuration */
    
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
    
    private func fetchDataFromCentralConfiguration(fromUrl: String, completionHandler: @escaping (String?, Error?) -> Void) -> Void {
        guard let url = URL(string: fromUrl) else { return }
        
        let urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.timeoutIntervalForResource = 5.0
        let urlSession = URLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: nil)
        
        let task = urlSession.dataTask(with: url, completionHandler: { data, response, error in
            
            guard let data = data else { return }
            
            guard let dataAsString = String(bytes: data, encoding: String.Encoding.utf8) else { return }
            
            if error != nil {
                print(error!.localizedDescription)
            }
            
            completionHandler(dataAsString, error)
            
        })
        
        task.resume()
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if configBaseUrl.contains("test") {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
        else {
            completionHandler(.performDefaultHandling, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
    }
    
    /**/
    
    /* Signature Verifier */
    
    private func verifySignature(configData: String, publicKey: String, signature: String) {
        do {
            let configDataData = trim(text: configData)!.data(using: .utf8)
            let publicKeyData = Data(base64Encoded: removeHeaderAndFooterFromRSACertificate(certificate: publicKey))
            let signatureData = Data(base64Encoded: removeAllWhitespace(data: signature))
            
            let isVerified = try? CC.RSA.verify(configDataData!, derKey: publicKeyData!, padding: .pkcs15, digest: .sha512, saltLen: 0, signedData: signatureData!)
            
            if isVerified == false || isVerified == nil {
                fatalError("Signature verification unsuccessful")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func removeHeaderAndFooterFromRSACertificate(certificate: String) -> String {
        let header = "-----BEGIN RSA PUBLIC KEY-----"
        let footer = "-----END RSA PUBLIC KEY-----"
        let cleanCert = removeAllWhitespace(data: certificate.replacingOccurrences(of: header, with: "")
            .replacingOccurrences(of: footer, with: ""))
        
        return cleanCert
    }
    
    private func removeAllWhitespace(data: String) -> String {
        return data.filter { !" \n\t\r".contains($0) }
    }
    
    private func trim(text: String?) -> String? {
        return text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    /**/
    
    /* MOPP Configuration */
    
    private func decodeMoppConfiguration(configData: String) throws -> MOPPConfiguration {
        do {
            return try JSONDecoder().decode(MOPPConfiguration.self, from: configData.data(using: .utf8)!)
        } catch {
            fatalError("Error decoding data: \(error.localizedDescription)")
        }
    }
    
    private struct MOPPConfiguration: Codable {
        let METAINF: MOPPMetaInf
        
        private enum MOPPConfigurationType: String, CodingKey {
            case METAINF = "META-INF"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: MOPPConfigurationType.self)
            METAINF = try container.decode(MOPPMetaInf.self, forKey: .METAINF)
        }
    }
    
    private struct MOPPMetaInf: Codable {
        let URL: String
        let DATE: String
        let SERIAL: Int
        let VER: Int
    }
    
    /**/
    
    /* Create new configuration file */
    private func createConfigurationFile(versionSerial: Int) -> String {
        return """
            {
            "centralConfigurationServiceUrl": "\(configBaseUrl)",
            "updateInterval": \(configUpdateInterval),
            "updateDate": "\(Date())",
            "versionSerial": \(versionSerial),
            "tslUrl": "\(configTslUrl)"
        }
        """
    }
    
    /**/
    
    /* Path and file saving / moving */
    private func getCurrentPath() -> String {
        return FileManager.default.currentDirectoryPath
    }
    
    private func saveToFileAndMove(contents: String, fileNameWithExtension: String) {
        
        let trimmedData = trim(text: contents)!
        let data = trimmedData.data(using: String.Encoding.utf8)
        let currentPathAsURL = URL(fileURLWithPath: getCurrentPath())
        let file = currentPathAsURL.appendingPathComponent(fileNameWithExtension)
        
        if FileManager.default.fileExists(atPath: file.path) {
            do {
                try FileManager.default.removeItem(atPath: file.path)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        
        let newFile = FileManager.default.createFile(atPath: (file.path), contents: data, attributes: nil)
        if newFile == false {
            fatalError("Error creating file at \(file.path)!")
        }
        moveFile(fileAtPath: file, fileNameWithExtension: fileNameWithExtension)
    }
    
    func moveFile(fileAtPath: URL, fileNameWithExtension: String) {
        let destinationDirectory: URL = URL(string: getCurrentPath())!.deletingLastPathComponent().appendingPathComponent("MoppApp").appendingPathComponent("MoppApp").appendingPathComponent(fileNameWithExtension)
        
        do {
            if FileManager.default.fileExists(atPath: destinationDirectory.path) {
                do {
                    try FileManager.default.removeItem(atPath: destinationDirectory.path)
                } catch {
                    fatalError(error.localizedDescription)
                }
            }
            
            try FileManager.default.moveItem(atPath: fileAtPath.path, toPath: destinationDirectory.path)
            
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    private func saveAndMoveConfigurationFiles(configData: String, publicKey: String, signature: String, defaultConfiguration: String) {
        saveToFileAndMove(contents: configData, fileNameWithExtension: "config.json")
        saveToFileAndMove(contents: publicKey, fileNameWithExtension: "publicKey.pub")
        saveToFileAndMove(contents: signature, fileNameWithExtension: "signature.rsa")
        saveToFileAndMove(contents: defaultConfiguration, fileNameWithExtension: "defaultConfiguration.json")
    }
    
    /**/
}

SettingsConfiguration().setupConfiguration()

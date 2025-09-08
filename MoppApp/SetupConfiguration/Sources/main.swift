#!/usr/bin/swift sh

import Foundation
import Security

// MARK: - Settings Configuration

class SettingsConfiguration {
    private let configBaseUrl: String
    private let configUpdateInterval: Int
    private let configTslUrl: String

    init() {
        let args = CommandLine.arguments
        self.configBaseUrl = args.indices.contains(1) ? args[1] : "https://id.eesti.ee"
        self.configUpdateInterval = args.indices.contains(2) ? Int(args[2]) ?? 4 : 4
        self.configTslUrl = args.indices.contains(3) ? args[3] : "https://ec.europa.eu/tools/lotl/eu-lotl.xml"
    }

    func setupConfiguration() throws {
        log("Starting configuration setup...")

        log("Config Base URL: \(configBaseUrl)")
        log("Update Interval: \(configUpdateInterval) hours")
        log("Config TSL URL: \(configTslUrl)")

        log("1 / 4 - Downloading configuration data...")
        let configData = try fetchData(from: "\(configBaseUrl)/config.json")
        let publicKey = try fetchData(from: "\(configBaseUrl)/config.pub")
        let signature = try fetchData(from: "\(configBaseUrl)/config.rsa")

        log("2 / 4 - Verifying signature...")
        try verifySignature(configData: configData, publicKey: publicKey, signature: signature)

        log("3 / 4 -  Creating default configuration file...")
        let decodedData = MOPPConfiguration(json: configData)
        let defaultConfiguration = createDefaultConfiguration(versionSerial: decodedData.METAINF.SERIAL)

        log("4 / 4 - Saving and moving files...")
        try saveFile(named: "config.json", content: configData)
        try saveFile(named: "publicKey.pub", content: publicKey)
        try saveFile(named: "signature.rsa", content: signature)
        try saveFile(named: "defaultConfiguration.json", content: defaultConfiguration)

        log("Default configuration initialized successfully!")
    }
}

// MARK: - Network Functions

extension SettingsConfiguration {
    private func fetchData(from urlString: String) throws -> String {
        guard let url = URL(string: urlString) else { throw ConfigurationError.invalidURL }
        guard let stringData = try? String(contentsOf: url, encoding: .utf8) else { throw ConfigurationError.invalidData }
        return stringData
    }
}

// MARK: - Signature Verification

extension SettingsConfiguration {
    private func verifySignature(configData: String, publicKey: String, signature: String) throws {
        guard !configData.isEmpty, !publicKey.isEmpty, !signature.isEmpty else {
            throw ConfigurationError.signatureVerificationFailed
        }
        guard let pubKey = Data(base64Encoded: publicKey
            .replacingOccurrences(of: "-----BEGIN RSA PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PUBLIC KEY-----", with: ""), options: .ignoreUnknownCharacters) else {
            throw ConfigurationError.signatureVerificationFailed
        }
        guard let sigData = Data(base64Encoded: signature, options: .ignoreUnknownCharacters) else {
            throw ConfigurationError.signatureVerificationFailed
        }
        let parameters: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecReturnPersistentRef: false
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(pubKey as CFData, parameters as CFDictionary, &error) else {
            log("Key importing failed \(error?.takeRetainedValue().localizedDescription ?? "")")
            throw ConfigurationError.signatureVerificationFailed
        }
        let algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA512
        let result = SecKeyVerifySignature(key, algorithm, Data(configData.utf8) as CFData, sigData as CFData, &error)
        if !result {
            log("Signature verifying failed \(error?.takeRetainedValue().localizedDescription ?? "")")
            throw ConfigurationError.signatureVerificationFailed
        }
        log("Signature verified successfully!")
    }
}

// MARK: - Configuration File Management

extension SettingsConfiguration {
    private func createDefaultConfiguration(versionSerial: Int) -> String {
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

    private func saveFile(named fileName: String, content: String) throws {
        let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(fileName)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        log("File saved: \(fileURL.path)")
    }
}

struct MOPPConfiguration: Codable {
    struct MetaInf: Codable {
        let URL: String
        let DATE: String
        let SERIAL: Int
        let VER: Int
    }
    let METAINF: MetaInf

    private enum CodingKeys: String, CodingKey {
        case METAINF = "META-INF"
    }

    init(json: String) {
        do {
            self = try JSONDecoder().decode(MOPPConfiguration.self, from: json.data(using: .utf8)!)
        } catch {
            fatalError("Error decoding data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Error Handling

enum ConfigurationError: Error {
    case invalidURL
    case invalidData
    case signatureVerificationFailed
}

// MARK: - Logger

func log(_ message: String) {
    NSLog("[\(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))] \(message)")
}

// MARK: - Run Script

try SettingsConfiguration().setupConfiguration()

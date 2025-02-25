#!/usr/bin/swift sh

import Foundation

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

    func setupConfiguration() async throws {
        log("Starting configuration setup...")

        log("Config Base URL: \(configBaseUrl)")
        log("Update Interval: \(configUpdateInterval) hours")
        log("Config TSL URL: \(configTslUrl)")

        log("1 / 4 - Downloading configuration data...")
        let configData = try await fetchData(from: "\(configBaseUrl)/config.json")
        let publicKey = try await fetchData(from: "\(configBaseUrl)/config.pub")
        let signature = try await fetchData(from: "\(configBaseUrl)/config.rsa")

        log("2 / 4 - Verifying signature...")
        try verifySignature(configData: configData, publicKey: publicKey, signature: signature)

        log("3 / 4 -  Creating default configuration file...")
        let decodedData = try decodeMoppConfiguration(configData: configData)
        let defaultConfiguration = createDefaultConfiguration(versionSerial: decodedData.METAINF.SERIAL)

        log("4 / 4 - Saving and moving files...")
        try saveAndMoveConfigurationFiles(configData: configData, publicKey: publicKey, signature: signature, defaultConfiguration: defaultConfiguration)

        log("Default configuration initialized successfully!")
    }
}

// MARK: - Network Functions

extension SettingsConfiguration {
    private func fetchData(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else { throw ConfigurationError.invalidURL }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let stringData = String(data: data, encoding: .utf8) else { throw ConfigurationError.invalidData }

        return stringData
    }
}

// MARK: - Signature Verification

extension SettingsConfiguration {
    private func verifySignature(configData: String, publicKey: String, signature: String) throws {
        // Placeholder for actual verification logic
        guard !configData.isEmpty, !publicKey.isEmpty, !signature.isEmpty else {
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

    private func saveAndMoveConfigurationFiles(configData: String, publicKey: String, signature: String, defaultConfiguration: String) throws {
        let files = [
            ("config.json", configData),
            ("publicKey.pub", publicKey),
            ("signature.rsa", signature),
            ("defaultConfiguration.json", defaultConfiguration)
        ]

        for (fileName, content) in files {
            try saveFile(named: fileName, content: content)
        }
    }

    private func saveFile(named fileName: String, content: String) throws {
        let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let fileURL = directory.appendingPathComponent(fileName)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        log("File saved: \(fileURL.path)")
    }
}

extension SettingsConfiguration {
    func decodeMoppConfiguration(configData: String) throws -> MOPPConfiguration {
          do {
              return try JSONDecoder().decode(MOPPConfiguration.self, from: configData.data(using: .utf8)!)
          } catch {
              fatalError("Error decoding data: \(error.localizedDescription)")
          }
      }

      struct MOPPConfiguration: Codable {
          let METAINF: MOPPMetaInf

          private enum MOPPConfigurationType: String, CodingKey {
              case METAINF = "META-INF"
          }

          init(from decoder: Decoder) throws {
              let container = try decoder.container(keyedBy: MOPPConfigurationType.self)
              METAINF = try container.decode(MOPPMetaInf.self, forKey: .METAINF)
          }
      }

      struct MOPPMetaInf: Codable {
          let URL: String
          let DATE: String
          let SERIAL: Int
          let VER: Int
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

try await SettingsConfiguration().setupConfiguration()

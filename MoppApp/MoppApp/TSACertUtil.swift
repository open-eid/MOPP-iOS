//
//  TSACertUtil.swift
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
import ASN1Decoder

class TSACertUtil {
    
    static let tsaFileFolder = "tsa-cert"
    
    static func getTsaCertFile() -> URL? {
        if !DefaultsHelper.tsaCertFileName.isNilOrEmpty {
            do {
                let documentsUrl = URL(fileURLWithPath: MoppFileManager.shared.documentsDirectoryPath())
                let tsaCertLocation = documentsUrl.appendingPathComponent(tsaFileFolder, isDirectory: true).appendingPathComponent(DefaultsHelper.tsaCertFileName ?? "-", isDirectory: false)
                if try tsaCertLocation.checkResourceIsReachable() {
                    return tsaCertLocation
                }
            } catch let openFileError {
                printLog("Failed to get '\(DefaultsHelper.tsaCertFileName ?? "TSA certificate")'. Error: \(openFileError.localizedDescription)")
                return nil
            }
        }
        return nil
    }
    
    static func getCertificate() -> X509Certificate? {
        let tsaCertLocation = getTsaCertFile()
        do {
            return try openCertificate(tsaCertLocation)
        } catch let openFileError {
            printLog("Failed to open '\(tsaCertLocation?.lastPathComponent ?? "TSA certificate")'. Error: \(openFileError.localizedDescription)")
            return nil
        }
    }
    
    static func openCertificate(_ certificateLocation: URL? = getTsaCertFile()) throws -> X509Certificate? {
        guard let certLocation = certificateLocation else { return nil }
        let fileData = try Data(contentsOf: certLocation)
        return try X509Certificate(data: fileData)
    }
    
    static func certificateString(_ certificateLocation: URL? = getTsaCertFile()) -> String? {
        guard let certLocation = certificateLocation else { return nil }
        do {
            return try String(contentsOf: certLocation)
                .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
                .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
                .trimWhitespacesAndNewlines()
        } catch let openFileError {
            printLog("Failed to open '\(certLocation.lastPathComponent)'. Error: \(openFileError.localizedDescription)")
            return nil
        }
    }
}

//
//  CertUtil.swift
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

import ASN1Decoder

class CertUtil {
    
    static func getCertFile(folder: String, fileName: String) -> URL? {
        do {
            let certLocation = MoppFileManager.cacheDirectory.appendingPathComponent(folder, isDirectory: true).appendingPathComponent(fileName, isDirectory: false)
            if try certLocation.checkResourceIsReachable() {
                return certLocation
            }
        } catch let openFileError {
            printLog("Failed to get '\(fileName)' certificate. Error: \(openFileError.localizedDescription)")
        }
        
        return nil
    }
    
    static func getCertificate(folder: String, fileName: String) -> X509Certificate? {
        let certLocation = getCertFile(folder: folder, fileName: fileName)
        do {
            return try openCertificate(certLocation)
        } catch let openFileError {
            printLog("Failed to open '\(certLocation?.lastPathComponent ?? "certificate")'. Error: \(openFileError.localizedDescription)")
            return nil
        }
    }
    
    static func openCertificate(_ certificateLocation: URL?) throws -> X509Certificate? {
        guard let certLocation = certificateLocation else { return nil }
        let fileData = try Data(contentsOf: certLocation)
        return try X509Certificate(data: fileData)
    }
    
    static func removeCertificate(folder: String, fileName: String) {
        let certLocation = getCertFile(folder: folder, fileName: fileName)
        if let certPath = certLocation?.path {
            MoppFileManager.shared.removeFile(withPath: certPath)
        }
    }
}

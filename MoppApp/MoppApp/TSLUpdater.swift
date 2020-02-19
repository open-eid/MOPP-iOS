//
//  TSLUpdater.swift
//  MoppApp
//
/*
 * Copyright 2020 Riigi Infosüsteemide Amet
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

class TSLUpdater {
    
    func checkForTSLUpdates() {
        guard let tslFilesBundlePath = Bundle.main.path(forResource: "tslFiles", ofType: "bundle") else { return }
        let tslFilesLibraryPath: String = MoppFileManager.shared.libraryDirectoryPath()
        
        let bundleFiles: [URL] = getCountryFileLocations(inPath: tslFilesBundlePath)
        let libraryFiles: [URL] = getCountryFileLocations(inPath: tslFilesLibraryPath)
        
        guard bundleFiles.count > 0 else { NSLog("No TSL files found in Bundle"); return }
        
        var bundleTSLVersions: [String : Int] = [:]
        var libraryTSLVersions: [String : Int] = [:]
        
        var isMasterTSLUpdated: Bool = false
        
        for bundleFile in bundleFiles {
            let fileName: String = bundleFile.deletingPathExtension().lastPathComponent
            bundleTSLVersions[fileName] = getTSLVersion(fromFile: bundleFile)
        }
        
        for libraryFile in libraryFiles {
            let fileName: String = libraryFile.deletingPathExtension().lastPathComponent
            libraryTSLVersions[fileName] = getTSLVersion(fromFile: libraryFile)
        }
        
        for (bundleCountry, bundleVersion) in bundleTSLVersions {
            if !libraryTSLVersions.isEmpty {
                for (libraryCountry, libraryVersion) in libraryTSLVersions {
                    if isTSLExistent(forCountry: libraryCountry) && bundleCountry == libraryCountry && bundleVersion > libraryVersion {
                        NSLog("\(libraryCountry) needs updating, updating version \(libraryVersion) to \(bundleVersion) from Bundle...")
                        updateCountryTSL(country: bundleCountry)
                        if !isMasterTSLUpdated { updateMasterTSL(); isMasterTSLUpdated = true }
                    } else {
                        logTSLVersions(bundleCountry: bundleCountry, bundleVersion: bundleVersion, libraryCountry: libraryCountry, libraryVersion: libraryVersion)
                    }
                }
                if !isTSLExistent(forCountry: bundleCountry) {
                    NSLog("\(bundleCountry) (version \(bundleVersion)) does not exist")
                    updateCountryTSL(country: bundleCountry)
                    if !isMasterTSLUpdated { updateMasterTSL(); isMasterTSLUpdated = true }
                }
            } else {
                NSLog("\(bundleCountry) TSL does not exist, copying version \(bundleVersion)...")
                updateCountryTSL(country: bundleCountry)
                if !isMasterTSLUpdated { updateMasterTSL(); isMasterTSLUpdated = true }
            }
        }
    }
    
    private func logTSLVersions(bundleCountry: String, bundleVersion: Int, libraryCountry: String, libraryVersion: Int) -> Void {
        if bundleCountry == libraryCountry {
            NSLog("\(libraryCountry) does not need updating, Library version: \(libraryVersion), Bundle version: \(bundleVersion)")
        }
    }
    
    private func updateMasterTSL() {
        let tslFilesBundlePath = Bundle.main.path(forResource: "tslFiles", ofType: "bundle") ?? ""
        let libraryFilePath: URL = URL(fileURLWithPath: MoppFileManager.shared.libraryDirectoryPath(), isDirectory: true)
        let masterTSLBundleLocation: URL = URL(fileURLWithPath: tslFilesBundlePath, isDirectory: true).appendingPathComponent("eu-lotl.xml")
        
        let masterTSLLibraryLocation: URL = libraryFilePath.appendingPathComponent("eu-lotl.xml")
        
        if FileManager.default.fileExists(atPath: masterTSLLibraryLocation.path) {
            NSLog("Overwriting master TSL...")
            removeEtag(destination: masterTSLLibraryLocation)
            MoppFileManager().overwriteFile(from: masterTSLBundleLocation, to: masterTSLLibraryLocation)
        } else {
            NSLog("Copying master TSL to Library directory from Bundle...")
            _ = MoppFileManager().copyFile(withPath: masterTSLBundleLocation.path, toPath: masterTSLLibraryLocation.path)
        }
    }
    
    private func isTSLExistent(forCountry country: String) -> Bool {
        return FileManager.default.fileExists(atPath: URL(fileURLWithPath: MoppFileManager.shared.libraryDirectoryPath(), isDirectory: true).appendingPathComponent("\(country).xml").path)
    }
    
    private func updateCountryTSL(country: String) -> Void {
        guard let tslFilesBundlePath = Bundle.main.path(forResource: "tslFiles", ofType: "bundle") else { return }
        let bundleFiles = getCountryFileLocations(inPath: tslFilesBundlePath)
        
        guard bundleFiles.count > 0 else { NSLog("No TSL files found in Bundle"); return }
        
        for countryFilePath in bundleFiles {
            let libraryFilePath: URL = URL(fileURLWithPath: MoppFileManager.shared.libraryDirectoryPath(), isDirectory: true).appendingPathComponent(countryFilePath.lastPathComponent)
            if countryFilePath.deletingPathExtension().lastPathComponent == country {
                if FileManager.default.fileExists(atPath: libraryFilePath.path) {
                    NSLog("Overwriting \(countryFilePath.lastPathComponent) TSL...")
                    removeEtag(destination: libraryFilePath)
                    MoppFileManager().overwriteFile(from: countryFilePath, to: libraryFilePath)
                } else {
                    NSLog("Updating \(countryFilePath.lastPathComponent) TSL from Bundle...")
                    _ = MoppFileManager().copyFile(withPath: countryFilePath.path, toPath: libraryFilePath.path)
                }
            }
        }
    }
    
    private func removeEtag(destination: URL) -> Void {
        let etagFile = destination.appendingPathExtension("etag")
        if FileManager.default.fileExists(atPath: etagFile.path) {
            NSLog("Removing \(destination.lastPathComponent) etag...")
            MoppFileManager().removeFile(withPath: etagFile.path)
        }
    }
    
    private func getTSLVersion(fromFile fileLocation: URL) -> Int {
        var version: Int = 0
        TSLVersionChecker().getTSLVersion(filePath: fileLocation) { (tslVersion) in
            if !tslVersion.isEmpty {
                version = Int(tslVersion) ?? 0
            }
        }
        
        return version
    }
    
    private func getCountryFileLocations(inPath tslFilesLocation: String) -> [URL] {
        var listOfFilesInBundle: [URL] = []
        do {
            let fileURLs = try FileManager().contentsOfDirectory(at: URL(fileURLWithPath: tslFilesLocation, isDirectory: true), includingPropertiesForKeys: nil)
            
            for file in fileURLs {
                if !file.lastPathComponent.starts(with: ".") && file.deletingPathExtension().lastPathComponent.count == 2 {
                    listOfFilesInBundle.append(file)
                }
            }
        } catch {
            NSLog("Error getting contents of directory \(tslFilesLocation)")
        }
        
        return listOfFilesInBundle
    }
}

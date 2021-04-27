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

    private var bundleFiles: [URL] = []
    private var bundleTSLVersions: [String : Int] = [:]
    private var libraryTSLVersions: [String : Int] = [:]

    var isMasterTSLUpdated: Bool = false

    func checkForTSLUpdates() -> Void {
        let filesInBundle: [URL] = getCountryFileLocations(inPath: getTSLFilesBundlePath())
        let filesInLibrary: [URL] = getCountryFileLocations(inPath: getLibraryDirectoryPath())

        assignFilesInBundle()

        guard getBundleFilesCount() > 0 else { NSLog("No TSL files found in Bundle"); return }

        assignBundleFileVersions(filesInBundle: filesInBundle)

        assignLibraryFileVersions(filesInLibrary: filesInLibrary)

        for (bundleCountry, bundleVersion) in bundleTSLVersions {
            if !isLibraryTSLVersionsEmpty() {
                for (libraryCountry, libraryVersion) in libraryTSLVersions {
                    updateTSLFromBundleIfNeeded(libraryCountry: libraryCountry, libraryVersion: libraryVersion, bundleCountry: bundleCountry, bundleVersion: bundleVersion)
                }
                addTSLFromBundleIfNotExistent(bundleCountry: bundleCountry, bundleVersion: bundleVersion)
            } else {
                addTSLFromBundleIfNotExistent(bundleCountry: bundleCountry, bundleVersion: bundleVersion)
            }
        }

        copyOtherTSLBundleFilesToLibrary(inPath: getTSLFilesBundlePath())
    }
    
    public func getLOTLFileURL() -> URL? {
        let tslFilesBundlePath: String = getTSLFilesBundlePath()
        guard !tslFilesBundlePath.isEmpty else {
            NSLog("Unable to get TSL files bundle path")
            return nil
        }
        
        for file in getFilesFromBundle(inPath: tslFilesBundlePath) {
            if file.lastPathComponent == "eu-lotl.xml" {
                do {
                    if try file.checkResourceIsReachable() {
                        return file
                    }
                } catch let error {
                    NSLog("Unable to check if \(file.lastPathComponent) is reachable. Error: \(error)")
                }
            }
        }
        
        return nil
        
    }

    public func getTSLFilesBundlePath() -> String {
        guard let tslFilesBundlePath: String = Bundle.main.path(forResource: "tslFiles", ofType: "bundle") else { return "" }

        return tslFilesBundlePath
    }
    
    public func getCountryFileLocations(inPath tslFilesLocation: String) -> [URL] {
        var countryFilesLocations: [URL] = []

        for file in getFilesFromBundle(inPath: tslFilesLocation) {
            if !file.lastPathComponent.starts(with: ".") {
                countryFilesLocations.append(file)
            }
        }

        return countryFilesLocations
    }
    
    public func getTSLVersion(fromFile fileLocation: URL) -> Int {
        var version: Int = 0
        TSLVersionChecker().getTSLVersion(filePath: fileLocation) { (tslVersion) in
            if !tslVersion.isEmpty {
                version = Int(tslVersion) ?? 0
            }
        }

        return version
    }

    private func getLibraryDirectoryPath() -> String {
        return MoppFileManager.shared.libraryDirectoryPath()
    }

    private func getBundleFilesCount() -> Int {
        return bundleFiles.count
    }

    private func updateTSLFromBundleIfNeeded(libraryCountry: String, libraryVersion: Int, bundleCountry: String, bundleVersion: Int) -> Void {
        if isTSLExistent(forCountry: libraryCountry) && bundleCountry == libraryCountry && bundleVersion > libraryVersion {
            NSLog("\(libraryCountry) needs updating, updating version \(libraryVersion) to \(bundleVersion) from Bundle...")
            updateCountryTSL(country: bundleCountry)
            if !isMasterTSLUpdated { updateMasterTSL() }
        } else {
            logTSLVersions(bundleCountry: bundleCountry, bundleVersion: bundleVersion, libraryCountry: libraryCountry, libraryVersion: libraryVersion)
        }
    }

    private func addTSLFromBundleIfNotExistent(bundleCountry: String, bundleVersion: Int) -> Void {
        if !isTSLExistent(forCountry: bundleCountry) {
            NSLog("\(bundleCountry) (version \(bundleVersion)) does not exist")
            updateCountryTSL(country: bundleCountry)
            if !isMasterTSLUpdated { updateMasterTSL() }
        }
    }

    private func assignBundleFileVersions(filesInBundle: [URL]) -> Void {
        for bundleFile in filesInBundle {
            if !bundleFile.hasDirectoryPath {
                let fileName: String = bundleFile.deletingPathExtension().lastPathComponent
                bundleTSLVersions[fileName] = getTSLVersion(fromFile: bundleFile)
            }
        }
    }

    private func assignLibraryFileVersions(filesInLibrary: [URL]) -> Void {
        for libraryFile in filesInLibrary {
            if !libraryFile.hasDirectoryPath {
                let fileName: String = libraryFile.deletingPathExtension().lastPathComponent
                libraryTSLVersions[fileName] = getTSLVersion(fromFile: libraryFile)
            }
        }
    }

    private func isLibraryTSLVersionsEmpty() -> Bool {
        return libraryTSLVersions.isEmpty
    }

    private func logTSLVersions(bundleCountry: String, bundleVersion: Int, libraryCountry: String, libraryVersion: Int) -> Void {
        if bundleCountry == libraryCountry {
            NSLog("\(libraryCountry) does not need updating, Library version: \(libraryVersion), Bundle version: \(bundleVersion)")
        }
    }

    private func updateMasterTSL() -> Void {
        let tslFilesBundlePath = Bundle.main.path(forResource: "tslFiles", ofType: "bundle") ?? ""
        let libraryFilePath: URL = URL(fileURLWithPath: MoppFileManager.shared.libraryDirectoryPath(), isDirectory: true)
        let masterTSLBundleLocation: URL = URL(fileURLWithPath: tslFilesBundlePath, isDirectory: true).appendingPathComponent("eu-lotl.xml")

        let masterTSLLibraryLocation: URL = libraryFilePath.appendingPathComponent("eu-lotl.xml")

        if FileManager.default.fileExists(atPath: masterTSLLibraryLocation.path) {
            overWriteFile(sourceFilePath: masterTSLBundleLocation, destinationFilePath: masterTSLLibraryLocation)
        } else {
            copyBundleFileToLibrary(sourceFilePath: masterTSLBundleLocation, destinationFilePath: masterTSLLibraryLocation)
        }

        isMasterTSLUpdated = true
    }

    private func isTSLExistent(forCountry country: String) -> Bool {
        return FileManager.default.fileExists(atPath: URL(fileURLWithPath: MoppFileManager.shared.libraryDirectoryPath(), isDirectory: true).appendingPathComponent("\(country).xml").path)
    }

    private func updateCountryTSL(country: String) -> Void {
        for countryFilePath in bundleFiles {
            let libraryFilePath: URL = URL(fileURLWithPath: MoppFileManager.shared.libraryDirectoryPath(), isDirectory: true).appendingPathComponent(countryFilePath.lastPathComponent)
            if countryFilePath.deletingPathExtension().lastPathComponent == country {
                if FileManager.default.fileExists(atPath: libraryFilePath.path) {
                    overWriteFile(sourceFilePath: countryFilePath, destinationFilePath: libraryFilePath)
                } else {
                    copyBundleFileToLibrary(sourceFilePath: countryFilePath, destinationFilePath: libraryFilePath)
                }
            }
        }
    }

    private func copyBundleFileToLibrary(sourceFilePath: URL, destinationFilePath: URL) -> Void {
        NSLog("Updating \(sourceFilePath.lastPathComponent) from Bundle...")
        _ = MoppFileManager().copyFile(withPath: sourceFilePath.path, toPath: destinationFilePath.path)
    }

    private func overWriteFile(sourceFilePath: URL, destinationFilePath: URL) -> Void {
        NSLog("Overwriting \(sourceFilePath.lastPathComponent)...")
        removeEtag(destination: destinationFilePath)
        MoppFileManager().overwriteFile(from: sourceFilePath, to: destinationFilePath)
    }

    private func assignFilesInBundle() -> Void {
        guard let tslFilesBundlePath = Bundle.main.path(forResource: "tslFiles", ofType: "bundle") else { return }
        let tslBundleFiles = getCountryFileLocations(inPath: tslFilesBundlePath)

        bundleFiles.removeAll()

        for countryFilePath in tslBundleFiles {
            NSLog("Getting \(countryFilePath.lastPathComponent) from Bundle...")
            bundleFiles.append(countryFilePath)
        }
    }

    private func removeEtag(destination: URL) -> Void {
        let etagFile = destination.appendingPathExtension("etag")
        if FileManager.default.fileExists(atPath: etagFile.path) {
            NSLog("Removing \(destination.lastPathComponent) etag...")
            MoppFileManager().removeFile(withPath: etagFile.path)
        }
    }

    private func getOtherTSLBundleFiles(inPath tslFilesLocation: String) -> [URL] {
        var otherBundleFilesLocations: [URL] = []

        for file in getFilesFromBundle(inPath: tslFilesLocation) {
            let fileName: String = file.deletingPathExtension().lastPathComponent

            if !file.lastPathComponent.starts(with: ".") && fileName.count != 2 && !fileName.contains("_T") && !fileName.contains("-test-") && file.deletingPathExtension().lastPathComponent != "eu-lotl" {
                otherBundleFilesLocations.append(file)
            }
        }

        return otherBundleFilesLocations
    }

    private func copyOtherTSLBundleFilesToLibrary(inPath tslFilesLocation: String) {
        for file in getOtherTSLBundleFiles(inPath: tslFilesLocation) {
            let libraryFilePath: URL = URL(fileURLWithPath: MoppFileManager.shared.libraryDirectoryPath(), isDirectory: true).appendingPathComponent(file.lastPathComponent)
            copyBundleFileToLibrary(sourceFilePath: file, destinationFilePath: libraryFilePath)
        }
    }

    private func getFilesFromBundle(inPath tslFilesLocation: String) -> [URL] {
        var listOfFilesInBundle: [URL] = []

        do {
            let fileURLs = try FileManager().contentsOfDirectory(at: URL(fileURLWithPath: tslFilesLocation, isDirectory: true), includingPropertiesForKeys: nil)

            for file in fileURLs {
                if !file.lastPathComponent.starts(with: ".") {
                    listOfFilesInBundle.append(file)
                }
            }
        } catch {
            NSLog("Error getting contents of directory \(tslFilesLocation)")
        }

        return listOfFilesInBundle
    }
}

//
//  TSLUpdater.swift
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

class TSLUpdater {

    private static var bundleFiles: [URL] = []
    private static var bundleTSLVersions: [String : Int] = [:]
    private static var libraryTSLVersions: [String : Int] = [:]

    static var isMasterTSLUpdated: Bool = false

    static func checkForTSLUpdates() -> Void {
        printLog("Checking for TSL updates")
        let filesInBundle: [URL] = getCountryFileLocations(inPath: getTSLFilesBundlePath())
        let filesInLibrary: [URL] = getCountryFileLocations(inPath: getLibraryDirectoryPath())

        assignFilesInBundle()

        guard getBundleFilesCount() > 0 else { printLog("No TSL files found in Bundle"); return }

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
    
    public static func getLOTLFileURL() -> URL? {
        printLog("Getting TSL files bundle path")
        let tslFilesBundlePath: String = getTSLFilesBundlePath()
        guard !tslFilesBundlePath.isEmpty else {
            printLog("Unable to get TSL files bundle path")
            return nil
        }
        
        printLog("TSL files bundle path: \(tslFilesBundlePath)")
        
        for file in getFilesFromBundle(inPath: tslFilesBundlePath) {
            if file.lastPathComponent == "eu-lotl.xml" {
                printLog("Checking if '\(file.lastPathComponent)' is reachable")
                do {
                    if try file.checkResourceIsReachable() {
                        return file
                    }
                } catch let error {
                    printLog("Unable to check if \(file.lastPathComponent) is reachable. Error: \(error.localizedDescription)")
                }
            }
        }
        
        return nil
        
    }

    public static func getTSLFilesBundlePath() -> String {
        guard let tslFilesBundlePath: String = Bundle.main.path(forResource: "tslFiles", ofType: "bundle") else { return "" }

        return tslFilesBundlePath
    }
    
    public static func getCountryFileLocations(inPath tslFilesLocation: String) -> [URL] {
        var countryFilesLocations: [URL] = []

        for file in getFilesFromBundle(inPath: tslFilesLocation) {
            if !file.lastPathComponent.starts(with: ".") && file.pathExtension == "xml" {
                countryFilesLocations.append(file)
            }
        }

        return countryFilesLocations
    }
    
    public static func getTSLVersion(fromFile fileLocation: URL) -> Int {
        printLog("Getting TSL version for file: \(fileLocation.lastPathComponent)")
        var version: Int = 0
        TSLVersionChecker().getTSLVersion(filePath: fileLocation) { (tslVersion) in
            if !tslVersion.isEmpty {
                version = Int(tslVersion) ?? 0
                printLog("TSL version: \(version)")
            } else {
                printLog("TSL version is empty")
            }
        }

        return version
    }

    public static func getLibraryDirectoryPath() -> String {
        return MoppFileManager.shared.libraryDirectoryPath()
    }

    private static func getBundleFilesCount() -> Int {
        return bundleFiles.count
    }

    private static func updateTSLFromBundleIfNeeded(libraryCountry: String, libraryVersion: Int, bundleCountry: String, bundleVersion: Int) -> Void {
        if isTSLExistent(forCountry: libraryCountry) && bundleCountry == libraryCountry && bundleVersion > libraryVersion {
            printLog("\(libraryCountry) needs updating, updating version \(libraryVersion) to \(bundleVersion) from Bundle...")
            updateCountryTSL(country: bundleCountry)
            if !isMasterTSLUpdated { updateMasterTSL() }
        } else {
            logTSLVersions(bundleCountry: bundleCountry, bundleVersion: bundleVersion, libraryCountry: libraryCountry, libraryVersion: libraryVersion)
        }
    }

    private static func addTSLFromBundleIfNotExistent(bundleCountry: String, bundleVersion: Int) -> Void {
        if !isTSLExistent(forCountry: bundleCountry) {
            printLog("\(bundleCountry) (version \(bundleVersion)) does not exist")
            updateCountryTSL(country: bundleCountry)
            if !isMasterTSLUpdated { updateMasterTSL() }
        }
    }

    public static func assignBundleFileVersions(filesInBundle: [URL]) -> Void {
        for bundleFile in filesInBundle {
            if !bundleFile.hasDirectoryPath {
                let fileName: String = bundleFile.deletingPathExtension().lastPathComponent
                bundleTSLVersions[fileName] = getTSLVersion(fromFile: bundleFile)
            }
        }
    }

    private static func assignLibraryFileVersions(filesInLibrary: [URL]) -> Void {
        for libraryFile in filesInLibrary {
            if !libraryFile.hasDirectoryPath {
                let fileName: String = libraryFile.deletingPathExtension().lastPathComponent
                libraryTSLVersions[fileName] = getTSLVersion(fromFile: libraryFile)
            }
        }
    }

    private static func isLibraryTSLVersionsEmpty() -> Bool {
        return libraryTSLVersions.isEmpty
    }

    private static func logTSLVersions(bundleCountry: String, bundleVersion: Int, libraryCountry: String, libraryVersion: Int) -> Void {
        if bundleCountry == libraryCountry {
            printLog("\(libraryCountry) does not need updating, Library version: \(libraryVersion), Bundle version: \(bundleVersion)")
        }
    }

    private static func updateMasterTSL() -> Void {
        printLog("Updating master TSL")
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

    private static func isTSLExistent(forCountry country: String) -> Bool {
        return FileManager.default.fileExists(atPath: URL(fileURLWithPath: MoppFileManager.shared.libraryDirectoryPath(), isDirectory: true).appendingPathComponent("\(country).xml").path)
    }

    private static func updateCountryTSL(country: String) -> Void {
        printLog("Updating country \(country) TSL")
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

    private static func copyBundleFileToLibrary(sourceFilePath: URL, destinationFilePath: URL) -> Void {
        printLog("Updating \(sourceFilePath.lastPathComponent) from Bundle...")
        _ = MoppFileManager().copyFile(withPath: sourceFilePath.path, toPath: destinationFilePath.path)
    }

    private static func overWriteFile(sourceFilePath: URL, destinationFilePath: URL) -> Void {
        printLog("Overwriting \(sourceFilePath.lastPathComponent)...")
        removeEtag(destination: destinationFilePath)
        MoppFileManager().overwriteFile(from: sourceFilePath, to: destinationFilePath)
    }

    private static func assignFilesInBundle() -> Void {
        guard let tslFilesBundlePath = Bundle.main.path(forResource: "tslFiles", ofType: "bundle") else { return }
        let tslBundleFiles = getCountryFileLocations(inPath: tslFilesBundlePath)

        bundleFiles.removeAll()

        for countryFilePath in tslBundleFiles {
            printLog("Getting \(countryFilePath.lastPathComponent) from Bundle...")
            bundleFiles.append(countryFilePath)
        }
    }

    private static func removeEtag(destination: URL) -> Void {
        let etagFile = destination.appendingPathExtension("etag")
        if FileManager.default.fileExists(atPath: etagFile.path) {
            printLog("Removing \(destination.lastPathComponent) etag...")
            MoppFileManager().removeFile(withPath: etagFile.path)
        }
    }

    private static func getOtherTSLBundleFiles(inPath tslFilesLocation: String) -> [URL] {
        var otherBundleFilesLocations: [URL] = []

        for file in getFilesFromBundle(inPath: tslFilesLocation) {
            let fileName: String = file.deletingPathExtension().lastPathComponent

            if !file.lastPathComponent.starts(with: ".") && fileName.count != 2 && !fileName.contains("_T") && !fileName.contains("-test-") && file.deletingPathExtension().lastPathComponent != "eu-lotl" {
                otherBundleFilesLocations.append(file)
            }
        }

        return otherBundleFilesLocations
    }

    private static func copyOtherTSLBundleFilesToLibrary(inPath tslFilesLocation: String) {
        for file in getOtherTSLBundleFiles(inPath: tslFilesLocation) {
            let libraryFilePath: URL = URL(fileURLWithPath: MoppFileManager.shared.libraryDirectoryPath(), isDirectory: true).appendingPathComponent(file.lastPathComponent)
            copyBundleFileToLibrary(sourceFilePath: file, destinationFilePath: libraryFilePath)
        }
    }

    private static func getFilesFromBundle(inPath tslFilesLocation: String) -> [URL] {
        printLog("Getting files from Bundle")
        var listOfFilesInBundle: [URL] = []

        do {
            let fileURLs = try FileManager().contentsOfDirectory(at: URL(fileURLWithPath: tslFilesLocation, isDirectory: true), includingPropertiesForKeys: nil)
            
            printLog("Files in Bundle: \(fileURLs)")

            for file in fileURLs {
                if !file.lastPathComponent.starts(with: ".") {
                    listOfFilesInBundle.append(file)
                }
            }
        } catch {
            printLog("Error getting contents of directory \(tslFilesLocation)")
        }

        return listOfFilesInBundle
    }
}

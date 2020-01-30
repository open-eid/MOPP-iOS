//
//  TSLDownload.swift
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

class TSLDownloader: NSObject {
    func checkForTSLUpdate() {
        if !isEtagFileInLibraryDirectory() || isTSLUpdateNeeded() {
            MSLog("Updating TSL...")
            updateCountryTSL()
        }
    }
    
    private func updateCountryTSL() {
        for file in MoppFileManager.shared.libraryFiles() {
            if isCountryTSLFile(file: file) {
                updateTSL(fullFileName: file.lastPathComponent)
            }
        }
    }
    
    private func isTSLUpdateNeeded() -> Bool {
        if isEtagFileInLibraryDirectory() {
            for file in MoppFileManager.shared.libraryFiles() {
                do {
                    if file.pathExtension == "etag" {
                        if isEtagNonExistantOrChanged(file: file) {
                            MSLog("ETAG changed")
                            saveEtagValues(filename: file.lastPathComponent, etagValue: try String(contentsOfFile: file.path))
                        } else {
                            return false
                        }
                    }
                } catch {
                    MSLog(error.localizedDescription)
                }
            }
        }
        
        return true
    }
    
    private func isEtagNonExistantOrChanged(file: URL) -> Bool {
        let userDefaults = UserDefaults.standard
        do {
            let etagValue = try String(contentsOfFile: file.path)
            MSLog("Etag value on device: \(userDefaults.string(forKey: file.lastPathComponent) ?? ""), Etag value in file: \(etagValue)")
            if (userDefaults.string(forKey: file.lastPathComponent) == nil || userDefaults.string(forKey: file.lastPathComponent) != etagValue) {
                return true
            }
        } catch {
            MSLog(error.localizedDescription)
            return false
        }
        
        return false
    }
    
    private func isCountryTSLFile(file: URL) -> Bool {
        let fileName = file.deletingPathExtension().lastPathComponent
        if file.path.hasSuffix("xml") && (fileName.count == 2 || fileName.contains("_T")) {
            return true
        }
        
        return false
    }
    
    private func isEtagFileInLibraryDirectory() -> Bool {
        var etagFound: Bool = false
        for file in MoppFileManager.shared.libraryFiles() {
            if file.pathExtension == "etag" {
                etagFound = true
            }
        }
        
        return etagFound
    }
    
    private func updateTSL(fullFileName: String) {
        let fileName = URL(string: fullFileName)!.deletingPathExtension().lastPathComponent
        MSLog("Downloading new TSL for \(fullFileName) from \(Configuration.getConfiguration().TSLURL)")
        LOTLDecoder().getUrl(LOTLUrl: Configuration.getConfiguration().TSLURL, country: fileName) { (url) in
            MSLog("Found TSL url: \(url)")
            self.downloadFile(fromUrl: URL(string: url)!, moveTo: URL(string: MoppFileManager.shared.libraryDirectoryPath())!, fileName: fullFileName)
            
        }
    }
    
    private func saveEtagValues(filename: String, etagValue: String) -> Void {
        UserDefaults.standard.setValue(etagValue, forKey: filename)
    }
    
    private func downloadFile(fromUrl url: URL, moveTo moveLocation: URL, fileName: String) {
        let task = URLSession.shared.downloadTask(with: url) { fileUrl, urlResponse, error in
            if let fileUrl = fileUrl {
                _ = MoppFileManager.shared.moveFile(withPath: fileUrl.path, toPath: moveLocation.appendingPathComponent(fileName).path, overwrite: true)
            }
        }
        task.resume()
    }

}

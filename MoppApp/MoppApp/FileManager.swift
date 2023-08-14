//
//  FileManager.swift
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

class MoppFileManager {
    static let shared = MoppFileManager()
    var fileManager: FileManager = FileManager()

    func documentsDirectoryPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory: String = paths[0]
        return documentsDirectory
    }
    
    func logsDirectoryPath() -> URL? {
        return URL(string: documentsDirectoryPath())?.appendingPathComponent("logs")
    }
    
    func logsDirectory() -> URL {
        let documentsURL = URL(fileURLWithPath: documentsDirectoryPath())
        return documentsURL.appendingPathComponent("logs")
    }

    func documentsFiles() -> [String] {
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        if let urlArr = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentAccessDateKey], options: .skipsHiddenFiles) {
            return urlArr.sorted { (currentFile, nextFile) -> Bool in
                guard let currentFileDate = try? currentFile.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate,
                      let nextFileDate = try? nextFile.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate else {
                    return false
                }
                return currentFileDate > nextFileDate
            }
            .map { $0.lastPathComponent }
        }
        
        return []
    }

    func removeDocumentsFile(with name: String) {
        var directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        directory.appendPathComponent(name)
        try! fileManager.removeItem(at: directory)
        if let inboxDirectoryPath = inboxDirectoryPath() {
            try? fileManager.removeItem(atPath: inboxDirectoryPath)
        }
    }
    
    func inboxDirectoryPath() -> String? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent("Inbox", isDirectory: true).path
    }

    func tempDocumentsDirectoryPath() -> String {
        let path: String = documentsDirectoryPath() + ("/temp")
        var isDir : ObjCBool = false
        if !(fileManager.fileExists(atPath: path, isDirectory: &isDir)) {
            try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: [FileAttributeKey.protectionKey: FileProtectionType.complete])
        }
        return path
    }

    func tempFilePath(withFileName fileName: String) -> String? {
        let tempPathURL = URL(fileURLWithPath: tempDocumentsDirectoryPath())
        let filePathURL = URL(fileURLWithPath: fileName.sanitize(),
            isDirectory: false, relativeTo: tempPathURL).absoluteURL

        // Create intermediate directories for possibility of creating temporary
        // file if filename contains relative path
        guard let _ = try? fileManager.createDirectory(at:
            filePathURL.deletingLastPathComponent(),
            withIntermediateDirectories: true, attributes: nil) else {
            return nil
        }
        
        return filePathURL.path
    }

    func filePath(withFileName fileName: String) -> String {
        let filePath: String = URL(fileURLWithPath: documentsDirectoryPath()).appendingPathComponent(fileName).path
        return filePath
    }
    
    func sharedDocumentsPath() -> String {
        guard let groupFolderUrl = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.ee.ria.digidoc.ios") else {
            return String()
        }
        return groupFolderUrl.appendingPathComponent("Temp").path
    }

    func sharedDocumentPaths() -> [String] {
        let cachePath: String = sharedDocumentsPath()
        var filePaths: [String] = []
        guard !cachePath.isEmpty else {
            printLog("Unable to get shared documents folder path")
            return filePaths
        }
        
        let files: [String]? = try? fileManager.contentsOfDirectory(atPath: cachePath)
        guard let filesInDirectory: [String] = files else {
            printLog("Unable to get shared documents directory")
            return filePaths
        }
        
        for file in filesInDirectory {
            filePaths.append("\(cachePath)/\(file)")
        }
        
        return filePaths
    }
    
    func libraryDirectoryPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        let libraryDirectory: String = paths[0]
        return libraryDirectory
    }
    
    func libraryFiles() -> [URL] {
        let directory = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!
        if let urlArr = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) {
            return urlArr.map { url -> (URL, Date) in
                (url, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
            }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
            .filter { file in
                return !file.path.filenameComponents().ext.isEmpty
            }
        }
        
        return []
    }

    func createTestContainer() -> String {
        let fileName = "\(MoppDateFormatter.shared.hHmmssddMMYYYY(toString: Date())).\(DefaultContainerFormat)"
        guard let bdocPath = Bundle.main.path(forResource: "test1", ofType: "bdoc") else {
            return String()
        }
        
        let bdocData = try! Data(contentsOf: URL(fileURLWithPath: bdocPath))
        createFile(atPath: filePath(withFileName: fileName), contents: bdocData)
        return fileName
    }

    func createFile(atPath filePath: String, contents fileContents: Data) {
        
        fileManager.createFile(atPath: filePath,
            contents: fileContents,
            attributes: [FileAttributeKey.protectionKey: FileProtectionType.complete])
        
        MoppLibContainerActions.sharedInstance().openContainer(
            withPath: filePath,
            success: { (_ container: MoppLibContainer?) in
                NotificationCenter.default.post(name: .containerChangedNotificationName, object: nil, userInfo: [kKeyContainerNew: container!])
            },
            failure: { (_ error: Error?) -> Void in
            })
    }
    
    func saveFile(fileURL: URL, _ folderName: String?, completionHandler: @escaping (Bool, URL?) -> Void) {
        let tsaCertDirectory: URL? = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(folderName ?? "tsa-cert", isDirectory: true)
        
        guard let saveDir: URL = tsaCertDirectory else { printLog("Failed to get \(tsaCertDirectory?.lastPathComponent ?? "requested") directory"); completionHandler(false, nil); return }
        do {
            _ = try saveDir.checkResourceIsReachable()
        } catch {
            // Create directory
            printLog("Directory '\(saveDir.lastPathComponent)' does not exist, creating...")
            do {
                _ = try fileManager.createDirectory(at: saveDir, withIntermediateDirectories: true, attributes: nil)
            } catch let saveDirerror {
                printLog("Failed to create '\(saveDir.lastPathComponent)' directory. Error: \(saveDirerror.localizedDescription)")
                completionHandler(false, nil)
                return
            }
        }
        
        do {
            let savedFileURL = saveDir.appendingPathComponent(fileURL.lastPathComponent)
            if fileManager.fileExists(atPath: savedFileURL.path) {
                try fileManager.removeItem(at: savedFileURL)
            }
            try fileManager.copyItem(at: fileURL, to: saveDir.appendingPathComponent( fileURL.lastPathComponent))
            completionHandler(true, savedFileURL)
        } catch let copyItemError {
            printLog("Failed to save '\(fileURL.lastPathComponent)'. Error: \(copyItemError.localizedDescription)")
            completionHandler(false, nil)
            return
        }
    }
    
    func saveFile(containerPath: String, fileName: String, completionHandler: @escaping (Bool, String?) -> Void) {
        let savedFilesDirectory: URL? = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Saved Files", isDirectory: true)
        let tempFilesDirectory: URL? = URL(string: MoppFileManager.shared.tempDocumentsDirectoryPath())
        
        guard let saveDir: URL = savedFilesDirectory else { printLog("Failed to get \(savedFilesDirectory?.lastPathComponent ?? "requested") directory"); completionHandler(false, nil); return }
        do {
            _ = try saveDir.checkResourceIsReachable()
        } catch {
            // Create directory
            printLog("Directory '\(saveDir.lastPathComponent)' does not exist, creating...")
            do {
                _ = try fileManager.createDirectory(at: saveDir, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                printLog("Failed to create '\(saveDir.lastPathComponent)' directory. Error: \(error.localizedDescription)")
                completionHandler(false, nil)
                return
            }
        }
        
        // Save file to temporary location
        let saveTempFileToLocation: String = saveDir.appendingPathComponent(fileName.sanitize()).path
        
        guard let tempDir: URL = tempFilesDirectory else { printLog("Failed to get \(tempFilesDirectory?.lastPathComponent ?? "requested") directory"); completionHandler(false, nil); return }
        let saveFileForCdocLocation: String = tempDir.appendingPathComponent(fileName).path
        
        let fileExtension = URL(fileURLWithPath: containerPath).pathExtension
        
        if fileExtension.isAsicContainerExtension {
            MoppLibContainerActions.sharedInstance()?.container(containerPath, saveDataFile: fileName, to: saveTempFileToLocation, success: {
                printLog("Successfully saved \(fileName) to 'Saved Files' directory")
                completionHandler(true, saveTempFileToLocation)
                return
            }, failure: { (error) in
                printLog("Failed to save file. Error: \(error?.localizedDescription ?? "No error to display")")
                completionHandler(false, nil)
                return
            })
        } else {
            let fileUrl: URL = URL(fileURLWithPath: tempDir.appendingPathComponent(fileName).path)
            do {
                let savedCdocFileData: Data? = try Data(contentsOf: URL(fileURLWithPath: saveFileForCdocLocation))
                try savedCdocFileData?.write(to: fileUrl)
                completionHandler(true, saveFileForCdocLocation)
            } catch let error {
                printLog("Failed to save file. Error: \(error.localizedDescription)")
                completionHandler(false, nil)
                return
            }
        }
    }
    
    func removeTempSavedFilesInDocuments(folderName: String) {
        do {
            let savedFilesDirectory: URL? = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(folderName, isDirectory: true)

            guard let saveDir: URL = savedFilesDirectory else { printLog("Failed to get \(savedFilesDirectory?.lastPathComponent ?? "requested") directory"); return }
            if fileManager.fileExists(atPath: saveDir.path) {
                try fileManager.removeItem(atPath: saveDir.path)
                printLog("Folder '\(saveDir.lastPathComponent)' removed!")
            } else {
                printLog("Folder '\(saveDir.lastPathComponent)' does not exist")
            }
        } catch let error {
            printLog("Error removing folder. Error \(error.localizedDescription)")
        }
    }

    func removeFile(withName fileName: String) {
        do {
            try fileManager.removeItem(atPath: filePath(withFileName: fileName))
        } catch {
            printLog("removeFileWithName error: \(error.localizedDescription)")
        }
    }

    func removeFile(withPath filePath: String) {
        do {
            try fileManager.removeItem(atPath: filePath)
        } catch {
            printLog("removeFileWithPath error: \(error.localizedDescription)")
        }
    }
    
    func removeFilesFromSharedFolder() {
        let sharedFiles = sharedDocumentPaths().compactMap { URL(fileURLWithPath: $0) }
        
        for sharedFile: URL in sharedFiles {
            removeFile(withPath: sharedFile.path)
        }
    }

    func fileExists(_ sourcePath: String) -> Bool {
        return fileManager.fileExists(atPath: sourcePath)
    }
    
    func directoryExists(_ sourcePath: String) -> Bool {
        var isDir: ObjCBool = false
        let directoryExists = fileManager.fileExists(atPath: sourcePath, isDirectory: &isDir)
        return isDir.boolValue && directoryExists
    }
    
    func moveFile(withPath sourcePath: String, toPath destinationPath: String, overwrite: Bool) -> Bool {
        if overwrite && fileExists(destinationPath) {
            removeFile(withPath: destinationPath)
        }
        do {
            try fileManager.moveItem(atPath: sourcePath, toPath: destinationPath)
        } catch {
            printLog("moveFileWithPath error: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
    func renameFile(withPath sourcePath: URL, toPath destinationPath: URL) -> Bool {
        do {
            guard let newUrl: URL = try fileManager.replaceItemAt(sourcePath, withItemAt: destinationPath), fileExists(newUrl.path) else {
                printLog("Failed to replace file or file not found")
                return false
            }
        } catch let error {
            printLog("Error while renaming file: \(error.localizedDescription)")
            return false
        }
        
        return true
    }

    func copyFile(withPath sourcePath: String, toPath destinationPath: String) -> String {
        return copyFile(withPath: sourcePath, toPath: destinationPath, duplicteCount: 0)
    }

    func copyFile(withPath sourcePath: String, toPath destinationPath: String, duplicteCount count: Int) -> String {
        var finalName: String = destinationPath
        if count > 0 {
            let components = finalName.filenameComponents()
            finalName = components.name + ("(\(count)).\(components.ext)")
        }
        
        if fileExists(finalName) {
            return copyFile(withPath: sourcePath, toPath: destinationPath, duplicteCount: count + 1)
        }

        do {
            try fileManager.copyItem(atPath: sourcePath, toPath: finalName)
        } catch {
            printLog("copyFileWithPath error: \(error.localizedDescription)")
        }
        return finalName
    }
    
    func overwriteFile(from source: URL, to destination: URL) {
        removeFile(withPath: destination.path)
        _ = copyFile(withPath: source.path, toPath: destination.path)
    }

    func duplicateFilename(atPath path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let (filenameBase, filenameExt) = url.lastPathComponent.filenameComponents()
        let pathWithoutName = path.substr(toLast: "/") ?? path
        var newPath = path
        var counter = 1
        while(MoppFileManager.shared.fileExists(newPath)) {
            newPath = pathWithoutName + filenameBase + "-\(counter)." + filenameExt
            counter += 1
        }
        return newPath
    }

    // Import files returned from UIDocumentPickerViewController
    func importFiles(with urls: [URL], completion: ((_ error: Error?, _ paths: [String]) -> Void)?) {
        importFiles_recursive(with: urls, importedPaths: [], completion: completion)
    }
    
    private func importFiles_recursive(with urls: [URL], importedPaths: [String], completion: ((_ error: Error?, _ paths: [String]) -> Void)?) {
        var mutableURLs: [URL] = urls
        
        guard let url: URL = mutableURLs.first else {
            completion?(nil, importedPaths)
            return
        }
        
        let coordinator: NSFileCoordinator = NSFileCoordinator(filePresenter: nil)
        let readingIntent: NSFileAccessIntent = NSFileAccessIntent.readingIntent(with: url, options: .withoutChanges)
        
        coordinator.coordinate(with: [readingIntent], queue: OperationQueue.main) { [weak self] error in
            var data: Data
            if error == nil {
                // Used to access folders on user device when opening container outside app (otherwise gives "Operation not permitted" error)
                url.startAccessingSecurityScopedResource()
                
                let safeURL: URL? = readingIntent.url
                
                guard let fileURL: URL = safeURL else {
                    printLog("Error opening imported file")
                    url.stopAccessingSecurityScopedResource()
                    completion?(NSError(domain: "Unable to open imported file", code: 1, userInfo: nil), [])
                    return
                }
                
                let isFileEmpty = MoppFileManager.isFileEmpty(fileUrl: fileURL)
                
                if urls.count == 1 && importedPaths.isEmpty && isFileEmpty {
                    printLog("Unable to open empty file")
                    url.stopAccessingSecurityScopedResource()
                    let error = NSError(domain: "Unable to open empty file", code: 3, userInfo: [NSLocalizedDescriptionKey: L(.fileImportFailedEmptyFile)])
                    completion?(error, [])
                    return
                }
                
                do {
                    data = try Data(contentsOf: fileURL)
                } catch let error {
                    printLog("Error opening file: \(error.localizedDescription)")
                    url.stopAccessingSecurityScopedResource()
                    completion?(NSError(domain: error.localizedDescription, code: 2, userInfo: nil), [])
                    return
                }
                
                guard let destinationPath = MoppFileManager.shared.tempFilePath(withFileName: fileURL.lastPathComponent.sanitize()) else {
                    printLog("Error opening file. Unable to get temp file path")
                    completion?(NSError(domain: String(), code: 0, userInfo: nil), [])
                    url.stopAccessingSecurityScopedResource()
                    return
                }
                
                if !isFileEmpty {
                    if !FileManager.default.fileExists(atPath: destinationPath) {
                        MoppFileManager.shared.createFile(atPath: destinationPath, contents: data)
                    }
                }
                
                _ = mutableURLs.removeFirst()
                
                var modifiedImportedPaths = importedPaths
                if !isFileEmpty {
                    modifiedImportedPaths.append(destinationPath)
                }
                
                url.stopAccessingSecurityScopedResource()
                
                self?.importFiles_recursive(with: mutableURLs, importedPaths: modifiedImportedPaths, completion: completion)
            } else {
                completion?(error, [])
            }
        }
    }
    
    static func isFileEmpty(fileUrl: URL) -> Bool {
        let fileSize: Double? = try? fileUrl.resourceValues(forKeys: [.fileSizeKey]).allValues.first?.value as? Double
        guard let fileSizeBytes = fileSize else { printLog("Could not get file size"); return true }
        return fileSizeBytes.isZero
    }
}

//
//  FileManager.swift
//  MoppApp
//
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

class MoppFileManager {
    static let shared = MoppFileManager()
    var fileManager: FileManager = FileManager()

    func documentsDirectoryPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory: String = paths[0]
        return documentsDirectory
    }

    func documentsFiles() -> [String] {
    
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        if let urlArr = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) {
            return urlArr.map { url -> (String, Date) in
                (url.lastPathComponent, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
            }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
            .filter { file in
                return !file.filenameComponents().ext.isEmpty
            }
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
            var error: Error?
            try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: [FileAttributeKey.protectionKey: FileProtectionType.complete])
        }
        return path
    }

    func tempFilePath(withFileName fileName: String) -> String? {
        let tempPathURL = URL(fileURLWithPath: tempDocumentsDirectoryPath())
        let filePathURL = URL(fileURLWithPath: fileName,
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
        let files = try! fileManager.contentsOfDirectory(atPath: sharedDocumentsPath())
        var array = [String]()
        for file in files {
            array.append("\(cachePath)/\(file)")
        }
        return array
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
    
    func saveFile(containerPath: String, fileName: String, completionHandler: @escaping (Bool, String?) -> Void) {
        let savedFilesDirectory: URL? = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Saved Files", isDirectory: true)
        let tempFilesDirectory: URL? = URL(string: MoppFileManager.shared.tempDocumentsDirectoryPath())
        
        guard let saveDir: URL = savedFilesDirectory else { NSLog("Failed to get \(savedFilesDirectory?.lastPathComponent ?? "requested") directory"); completionHandler(false, nil); return }
        do {
            _ = try saveDir.checkResourceIsReachable()
        } catch {
            // Create directory
            NSLog("Directory '\(saveDir.lastPathComponent)' does not exist, creating...")
            do {
                _ = try fileManager.createDirectory(at: saveDir, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                NSLog("Failed to create '\(saveDir.lastPathComponent)' directory. Error: \(error.localizedDescription)")
                completionHandler(false, nil)
                return
            }
        }
        
        // Save file to temporary location
        let saveTempFileToLocation: String = saveDir.appendingPathComponent(fileName).path
        
        guard let tempDir: URL = tempFilesDirectory else { NSLog("Failed to get \(tempFilesDirectory?.lastPathComponent ?? "requested") directory"); completionHandler(false, nil); return }
        let saveFileForCdocLocation: String = tempDir.appendingPathComponent(fileName).path
        
        if URL(fileURLWithPath: containerPath).pathExtension.isAsicContainerExtension {
            MoppLibContainerActions.sharedInstance()?.container(containerPath, saveDataFile: fileName, to: saveTempFileToLocation, success: {
                NSLog("Successfully saved \(fileName) to 'Saved Files' directory")
                completionHandler(true, saveTempFileToLocation)
                return
            }, failure: { (error) in
                NSLog("Failed to save file. Error: \(error?.localizedDescription ?? "No error to display")")
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
                NSLog("Failed to save file. Error: \(error.localizedDescription)")
                completionHandler(false, nil)
                return
            }
        }
    }
    
    func removeTempSavedFiles() {
        do {
            let savedFilesDirectory: URL? = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Saved Files", isDirectory: true)

            guard let saveDir: URL = savedFilesDirectory else { NSLog("Failed to get \(savedFilesDirectory?.lastPathComponent ?? "requested") directory"); return }
            if fileManager.fileExists(atPath: saveDir.path) {
                try fileManager.removeItem(atPath: saveDir.path)
                NSLog("Folder '\(saveDir.lastPathComponent)' removed!")
            } else {
                NSLog("Folder '\(saveDir.lastPathComponent)' does not exist")
            }
        } catch let error {
            NSLog("Error removing folder. Error \(error.localizedDescription)")
        }
    }

    func removeFile(withName fileName: String) {
        do {
            try fileManager.removeItem(atPath: filePath(withFileName: fileName))
        } catch {
            MSLog("removeFileWithName error: %@", error)
        }
    }

    func removeFile(withPath filePath: String) {
        do {
            try fileManager.removeItem(atPath: filePath)
        } catch {
            MSLog("removeFileWithPath error: %@", error)
        }
    }

    func fileExists(_ sourcePath: String) -> Bool {
        return fileManager.fileExists(atPath: sourcePath)
    }
    
    func moveFile(withPath sourcePath: String, toPath destinationPath: String, overwrite: Bool) -> Bool {
        if overwrite && fileExists(destinationPath) {
            removeFile(withPath: destinationPath)
        }
        do {
            try fileManager.moveItem(atPath: sourcePath, toPath: destinationPath)
        } catch {
            MSLog("moveFileWithPath error: %@", error)
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
            MSLog("copyFileWithPath error: %@", error)
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
        var mutableURLs = urls
        
        guard let url = mutableURLs.first else {
            completion?(nil, importedPaths)
            return
        }
        
        let isUrlSSR = url.startAccessingSecurityScopedResource()
        let coordinator = NSFileCoordinator(filePresenter: nil)
        let readingIntent = NSFileAccessIntent.readingIntent(with: url, options: .withoutChanges)
        
        coordinator.coordinate(with: [readingIntent], queue: OperationQueue.main) { [weak self] error in
            var data: Data!
            if error == nil {
                let safeURL = readingIntent.url
                
                data = try! Data(contentsOf: safeURL)
                
                guard let destinationPath = MoppFileManager.shared.tempFilePath(withFileName: safeURL.lastPathComponent) else {
                    completion?(NSError(domain: String(), code: 0, userInfo: nil), [])
                    return
                }
                
                if !FileManager.default.fileExists(atPath: destinationPath) {
                    MoppFileManager.shared.createFile(atPath: destinationPath, contents: data)
                }
                
                if isUrlSSR {
                    url.stopAccessingSecurityScopedResource()
                }
                
                _ = mutableURLs.removeFirst()
                
                var modifiedImportedPaths = importedPaths
                    modifiedImportedPaths.append(destinationPath)
                
                self?.importFiles_recursive(with: mutableURLs, importedPaths: modifiedImportedPaths, completion: completion)
            } else {
                if isUrlSSR {
                    url.stopAccessingSecurityScopedResource()
                }
                completion?(error, [])
            }
        }
    }
}

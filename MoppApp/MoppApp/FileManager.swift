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

    func setup() {
    }

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
                let components = file.filenameComponents()
                return !components.ext.isEmpty
            }
        }
        
        return []
    }

    func removeDocumentsFile(with name: String) {
        var directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        directory.appendPathComponent(name)
        try! fileManager.removeItem(at: directory)
    }

    func tempDocumentsDirectoryPath() -> String {
        let path: String = documentsDirectoryPath() + ("/temp")
        var isDir : ObjCBool = false
        if !(fileManager.fileExists(atPath: path, isDirectory: &isDir)) {
            var error: Error?
            try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        return path
    }

    func tempFilePath(withFileName fileName: String) -> String {
        let filePath: String = URL(fileURLWithPath: tempDocumentsDirectoryPath()).appendingPathComponent(fileName).path
        return filePath
    }

    func filePath(withFileName fileName: String) -> String {
        let filePath: String = URL(fileURLWithPath: documentsDirectoryPath()).appendingPathComponent(fileName).path
        return filePath
    }

    func uniqueFilePath(withFileName fileName: String) -> String {
        return filePath(withFileName: fileName, index: 0)
    }

    func filePath(withFileName fileName: String, index: Int) -> String {
        var filePath: String = URL(fileURLWithPath: documentsDirectoryPath()).appendingPathComponent(fileName).path
        if index > 0 {
            let components = filePath.filenameComponents()
            filePath = "\(components.name)(\(index)).\(components.ext)"
        }
        var isDir : ObjCBool = false
        if fileManager.fileExists(atPath: filePath, isDirectory: &isDir) {
            return self.filePath(withFileName: fileName, index: index + 1)
        }
        return filePath
    }
    
    func sharedDocumentsPath() -> String {
        guard let groupFolderUrl = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.ee.fob.digidoc.ios") else {
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

    func removeFiles(atPaths paths: [String]) {
        for file in paths {
            removeFile(withPath: file)
        }
    }

    func clearSharedCache() {
        let cachedDocs = sharedDocumentPaths()
        for file in cachedDocs {
            removeFile(withPath: file)
        }
    }

    func createTestContainer() -> String {
        let fileName = "\(MoppDateFormatter.shared.hHmmssddMMYYYY(toString: Date())).\(DefaultsHelper.newContainerFormat)"
        guard let bdocPath = Bundle.main.path(forResource: "test1", ofType: "bdoc") else {
            return String()
        }
        
        let bdocData = try! Data(contentsOf: URL(fileURLWithPath: bdocPath))
        createFile(atPath: filePath(withFileName: fileName), contents: bdocData)
        return fileName
    }

    func createFile(atPath filePath: String, contents fileContents: Data) {
        
        fileManager.createFile(atPath: filePath, contents: fileContents, attributes: nil)
        
        MoppLibContainerActions.sharedInstance().getContainerWithPath(
            filePath,
            success: { (_ container: MoppLibContainer?) in
                NotificationCenter.default.post(name: .containerChangedNotificationName, object: nil, userInfo: [kKeyContainerNew: container!])
            },
            failure: { (_ error: Error?) -> Void in
            })
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

    func moveFile(withPath sourcePath: String, toPath destinationPath: String, overwrite: Bool, outError:inout Error) throws {
        if overwrite && fileExists(destinationPath) {
            removeFile(withPath: destinationPath)
        }
        do {
            try fileManager.moveItem(atPath: sourcePath, toPath: destinationPath)
        } catch {
            MSLog("moveFileWithPath error: %@", error)
            outError = error
        }
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

}

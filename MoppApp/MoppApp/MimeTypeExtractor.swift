//
//  MimeTypeExtractor.swift
//  MoppApp
//
/*
* Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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
import ZIPFoundation


class MimeTypeExtractor {
    public static func getMimeTypeFromContainer(filePath: URL) -> String {
        
        var mimetype: String = ""
        
        guard let fileHandle = FileHandle(forReadingAtPath: filePath.path) else { return "" }
        let fileData = fileHandle.readData(ofLength: 4)
        // Check if file is zip format
        if fileData.starts(with: [0x50, 0x4b, 0x03, 0x04]) {
            guard let unzippedFile = unZipFile(filePath: filePath, fileName: "mimetype") else {
                return mimetype
            }
            
            mimetype = getMimetypeFromUnzippedContainer(filePath: unzippedFile)
            
            let unzippedFolder = unzippedFile.deletingLastPathComponent()
            
            removeUnzippedFolder(folderPath: unzippedFolder)
        }
        fileHandle.closeFile()
        
        if isDdoc(url: filePath) {
            return ContainerFormatDdocMimetype
        }
        
        if isCdoc(url: filePath) {
            return ContainerFormatCdocMimetype
        }
        
        return mimetype
    }
    
    public static func determineFileExtension(mimeType: String) -> String? {
        switch mimeType {
        case ContainerFormatAsiceMimetype:
            return ContainerFormatAsice
        case ContainerFormatAsicsMimetype:
            return ContainerFormatAsics
        case ContainerFormatDdocMimetype:
            return ContainerFormatDdoc
        case ContainerFormatCdocMimetype:
            return ContainerFormatCdoc
        case ContainerFormatAdocMimetype:
            return ContainerFormatAdoc
        default:
            return nil
        }
    }
    
    public static func determineContainer(mimetype: String, fileExtension: String) -> String {
        if mimetype == ContainerFormatAsiceMimetype && fileExtension == ContainerFormatBdoc {
            return ContainerFormatBdoc
        }
        
        if mimetype == ContainerFormatAsiceMimetype && fileExtension == ContainerFormatEdoc {
            return ContainerFormatEdoc
        }
        
        if mimetype == ContainerFormatAsiceMimetype && fileExtension == ContainerFormatAsiceShort {
            return ContainerFormatAsiceShort
        }
        
        if mimetype == ContainerFormatAsiceMimetype && fileExtension == ContainerFormatP12d {
            return ContainerFormatP12d
        }
        
        if mimetype == ContainerFormatAsicsShort && fileExtension == ContainerFormatAsicsShort {
            return ContainerFormatAsicsShort
        }
        
        // Google Drive may export ddoc files as xml
        if mimetype == ContainerFormatDdocMimetype && (fileExtension == ContainerFormatDdoc || fileExtension == FileFormatXml) {
            return ContainerFormatDdoc
        }
        
        // Google Drive may export cdoc files as xml
        if mimetype == ContainerFormatCdocMimetype && (fileExtension == ContainerFormatCdoc || fileExtension == FileFormatXml) {
            return ContainerFormatCdoc
        }
        
        return fileExtension
        
    }
    
    private static func unZipFile(filePath: URL, fileName: String) -> URL? {
        let outputPath = URL(fileURLWithPath: MoppFileManager.shared.tempDocumentsDirectoryPath(), isDirectory: true).appendingPathComponent(filePath.lastPathComponent).deletingPathExtension()
        guard let archive = Archive(url: filePath, accessMode: .read) else  {
            return nil
        }
        guard let fileInArchive = archive[fileName] else {
            return nil
        }
        var destinationLocation = URL(fileURLWithPath: outputPath.path)
        destinationLocation.appendPathComponent("mimetype")
        do {
            printLog("Extracting file: \(fileName)")
            _ = try archive.extract(fileInArchive, to: destinationLocation)
            return destinationLocation
        } catch {
            printLog("Unable to extract file \(fileInArchive). Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private static func isMimeTypeFilePresent(filePath: URL) -> Bool {
        return FileManager().fileExists(atPath: filePath.appendingPathComponent("mimetype").path)
    }
    
    private static func getMimetypeFromUnzippedContainer(filePath: URL) -> String {
        do {
            return try String(contentsOf: filePath, encoding: .utf8)
        } catch {
            printLog("Error getting contents of file \(filePath.lastPathComponent): \(error.localizedDescription)")
            return ""
        }
    }
    
    private static func removeUnzippedFolder(folderPath: URL) -> Void {
        MoppFileManager().removeFile(withPath: folderPath.path)
    }
    
    private static func isDdoc(url: URL) -> Bool {
        do {
            let fileData = try Data(contentsOf: url)
            guard !fileData.isEmpty else {
                return false
            }
            let fileDataAscii = String(data: fileData, encoding: .ascii)
            
            var isDdoc: Bool = false
            
            MimeTypeDecoder().getMimeType(fileString: fileDataAscii ?? "") { (containerExtension) in
                if containerExtension == ContainerFormatDdoc {
                    isDdoc = true
                }
            }
            
            return isDdoc
        } catch {
            printLog("Error getting url data \(error.localizedDescription)")
        }
        
        return false
    }
    
    private static func isCdoc(url: URL) -> Bool {
        do {
            let fileData = try Data(contentsOf: url)
            guard !fileData.isEmpty else {
                return false
            }
            let fileDataAscii = String(data: fileData, encoding: .ascii)
            
            var isCdoc: Bool = false
            
            MimeTypeDecoder().getMimeType(fileString: fileDataAscii ?? "") { (containerExtension) in
                if containerExtension == ContainerFormatCdoc {
                    isCdoc = true
                }
            }
            
            return isCdoc
        } catch {
            printLog("Error getting url data \(error.localizedDescription)")
        }
        
        return false
    }
}

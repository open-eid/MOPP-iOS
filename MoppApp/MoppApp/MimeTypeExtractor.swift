//
//  MimeTypeExtractor.swift
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
import Zip


class MimeTypeExtractor {
    public func getMimeTypeFromContainer(filePath: URL) -> String {
        
        var mimetype: String = ""
        
        guard let fileHandle = FileHandle(forReadingAtPath: filePath.path) else { return "" }
        let fileData = fileHandle.readData(ofLength: 4)
        if fileData.starts(with: [0x50, 0x4b, 0x03, 0x04]) {
            let unzippedFile: URL = unZipFile(filePath: filePath)
            let isMimeTypeFileExistent = isMimeTypeFilePresent(filePath: unzippedFile)
            if isMimeTypeFileExistent {
                mimetype = getMimetypeFromUnzippedContainer(filePath: unzippedFile)
            }
            
            removeUnzippedFolder(folderPath: unzippedFile)
        }
        fileHandle.closeFile()
        
        return mimetype
    }
    
    private func unZipFile(filePath: URL) -> URL {
        var unzippedFilePath: URL = URL(fileURLWithPath: "")
        do {
            Zip.addCustomFileExtension(filePath.pathExtension)
            unzippedFilePath = try Zip.quickUnzipFile(filePath)
        }
        catch {
            NSLog("Error unzipping file \(filePath.lastPathComponent): \(error)")
        }
        
        return unzippedFilePath
    }
    
    private func isMimeTypeFilePresent(filePath: URL) -> Bool {
        return FileManager().fileExists(atPath: filePath.appendingPathComponent("mimetype").path)
    }
    
    private func getMimetypeFromUnzippedContainer(filePath: URL) -> String {
        var mimetype: String = ""
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let mimetypeFile = documentsDirectory.appendingPathComponent(filePath.lastPathComponent, isDirectory: true).appendingPathComponent("mimetype")
            do {
                mimetype = try String(contentsOf: mimetypeFile, encoding: .utf8)
            } catch {
                NSLog("Error getting contents of file \(filePath.lastPathComponent): \(error)")
            }
        }
        
        return mimetype
    }
    
    private func removeUnzippedFolder(folderPath: URL) -> Void {
        MoppFileManager().removeFile(withPath: folderPath.path)
    }
}

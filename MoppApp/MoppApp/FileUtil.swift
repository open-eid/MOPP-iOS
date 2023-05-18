//
//  FileUtil.swift
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

struct FileUtil {
    
    static let fileNamePrefix = "newFile"
    static let defaultFileExtension = "txt"
    
    static func getSignDocumentFileName(containerPath: String) -> String {
        guard !containerPath.isEmpty else { return "" }
        let fileURL: URL? = URL(fileURLWithPath: containerPath)
        if let fileURL = fileURL {
            let fileName = fileURL.deletingPathExtension().lastPathComponent.sanitize()
            let fileExtension = fileURL.pathExtension
            
            if fileName.count <= 6 {
                return "\(fileName).\(fileExtension)"
            }
            
            return "\(fileName.prefix(3))...\(fileName.suffix(3)).\(fileExtension)"
        }
        return ""
    }
    
    static func getFileName(currentFileName: String) -> String {
        if currentFileName.isEmpty {
            return fileNamePrefix
        } else if currentFileName.starts(with: ".") {
            let url = URL(string: currentFileName)
            guard let fileExtension = url?.pathExtension else { return fileNamePrefix }
            return fileNamePrefix + fileExtension
        }
        
        return currentFileName
    }
    
    static func addDefaultExtension(url: URL) -> URL {
        if !url.pathExtension.isEmpty {
            return url
        }
        return url.appendingPathExtension(defaultFileExtension)
    }
}

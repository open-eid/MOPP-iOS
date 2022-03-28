//
//  FileDownloader.swift
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

class FileDownloader: NSObject, URLSessionDelegate {
    
    static let shared = FileDownloader()
    
    func downloadFile(url: URL, completion: @escaping (URL?) -> Void) {
        let downloadTask: URLSessionDownloadTask = URLSession(configuration: .default, delegate: self, delegateQueue: nil).downloadTask(with: url) { (fileTempUrl, response, error) in
            if error != nil { printLog("Unable to download file: \(error?.localizedDescription ?? "Unable to display error")"); return completion(nil) }
            if let fileTempUrl: URL = fileTempUrl {
                do {
                    let documentsPathFileURL: URL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Downloads", isDirectory: true).appendingPathComponent(url.lastPathComponent)
                    try FileManager.default.createDirectory(at: documentsPathFileURL, withIntermediateDirectories: true, attributes: nil)
                    let fileLocation: String = MoppFileManager.shared.copyFile(withPath: fileTempUrl.path, toPath: documentsPathFileURL.path)
                    return completion(URL(fileURLWithPath: fileLocation))
                } catch let error {
                    printLog("Failed to download file or create directory: \(error.localizedDescription)")
                    return completion(nil)
                }
            } else {
                printLog("Unable to get file temporary URL")
                return completion(nil)
            }
        }
        downloadTask.resume()
    }
    
    
    func downloadExternalFile(url: URL, completion: @escaping (URL?) -> Void) {
        if url.startAccessingSecurityScopedResource() {
            var error: NSError?
            
            NSFileCoordinator().coordinate(
                readingItemAt: url, options: .forUploading, error: &error) { _ in }
            
            if error != nil {
                printLog("Error getting file: \(error?.localizedDescription ?? "Unknown error")")
                return completion(nil)
            }
            
            printLog("External file downloaded")
            completion(url)
            
            url.stopAccessingSecurityScopedResource()
            return
        }
    }
}

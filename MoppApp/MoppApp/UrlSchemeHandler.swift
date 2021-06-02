//
//  UrlSchemeHandler.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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

class UrlSchemeHandler: NSObject, URLSessionDelegate {
    
    static let shared = UrlSchemeHandler()
    
    public func getFileLocationFromURL(url: URL?, completion: @escaping (URL?) -> Void) {
        self.handleURLScheme(url: url) { fileLocation in
            guard let fileURL: URL = fileLocation else {
                NSLog("Unable to get downloaded file location")
                return completion(nil)
            }
            do {
                if try fileURL.checkResourceIsReachable() {
                    return completion(fileURL)
                }
            } catch let error {
                NSLog("Unable to check if downloaded resource is reachable. Error: \(error.localizedDescription)")
                return completion(nil)
            }
        }
    }
    
    private func handleURLScheme(url: URL?, completion: @escaping (URL?) -> Void) {
        guard let url: URL = url else { return }
        let schemelessUrl: URL? = constructURLWithoutScheme(url: url)
        guard let link: URL = schemelessUrl, let unescapedLink: String = link.absoluteString.removingPercentEncoding else { return }
        let modifiedLinkString: String = unescapedLink.replacingOccurrences(of: "////", with: "//")
        if modifiedLinkString.isValidUrl {
            if let fileURL: URL = URL(string: modifiedLinkString) {
                downloadFile(url: fileURL) { fileLocation in
                    completion(fileLocation)
                }
            }
        }
    }
    
    private func downloadFile(url: URL, completion: @escaping (URL?) -> Void) {
        let downloadTask: URLSessionDownloadTask = URLSession(configuration: .default, delegate: self, delegateQueue: nil).downloadTask(with: url) { (fileTempUrl, response, error) in
            if let fileTempUrl: URL = fileTempUrl {
                do {
                    if error != nil { NSLog("Unable to download file: \(error?.localizedDescription ?? "Unable to display error")"); return completion(nil) }
                    let documentsPathFileURL: URL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Downloads", isDirectory: true).appendingPathComponent(url.lastPathComponent)
                    try FileManager.default.createDirectory(at: documentsPathFileURL, withIntermediateDirectories: true, attributes: nil)
                    let fileLocation: String = MoppFileManager.shared.copyFile(withPath: fileTempUrl.path, toPath: documentsPathFileURL.path)
                    return completion(URL(fileURLWithPath: fileLocation))
                } catch let error {
                    NSLog("Failed to download file or create directory: \(error.localizedDescription)")
                    return completion(nil)
                }
            }
        }
        downloadTask.resume()
    }
    
    private func constructURLWithoutScheme(url: URL?) -> URL? {
        guard let url = url else { return URL(string: "") }
        var urlComponents: URLComponents = URLComponents()
        if let urlHost = url.host, (urlHost != "https") {
            urlComponents.scheme = "https"
            urlComponents.host = url.host
            urlComponents.port = url.port
            urlComponents.path = url.path
            urlComponents.query = url.query
        } else {
            urlComponents.scheme = url.host
            urlComponents.host = url.path
            urlComponents.port = url.port
            urlComponents.query = url.query
        }
        
        
        return urlComponents.url
    }
}

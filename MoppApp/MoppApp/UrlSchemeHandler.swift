//
//  UrlSchemeHandler.swift
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

class UrlSchemeHandler: NSObject, URLSessionDelegate {
    
    static let shared = UrlSchemeHandler()
    
    public func getFileLocationFromURL(url: URL?, completion: @escaping (URL?) -> Void) {
        self.handleURLScheme(url: url) { fileLocation in
            guard let fileURL: URL = fileLocation else {
                printLog("Unable to get downloaded file location")
                return completion(nil)
            }
            do {
                if try fileURL.checkResourceIsReachable() {
                    return completion(fileURL)
                }
            } catch let error {
                printLog("Unable to check if downloaded resource is reachable. Error: \(error.localizedDescription)")
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
                FileDownloader.shared.downloadFile(url: fileURL) { fileLocation in
                    completion(fileLocation)
                }
            }
        }
    }
    
    private func constructURLWithoutScheme(url: URL?) -> URL? {
        guard let url: URL = url else { return URL(string: "") }
        
        let supportedURISchemes: [String] = ["https"]
        
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        if urlComponents?.scheme == "digidoc" {
            let urlString = url.absoluteString
            var cleanUrlString = ""
            if let urlHost = urlComponents?.host, supportedURISchemes.contains(urlHost) {
                cleanUrlString = urlString.replacingOccurrences(of: "digidoc://" + urlHost + "//", with: urlHost + "://")
            } else {
                cleanUrlString = urlString.replacingOccurrences(of: "digidoc://", with: "https://")
            }
            return URL(string: cleanUrlString)
        }
        return URL(string: "")
    }
}

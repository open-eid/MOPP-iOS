//
//  FileUtil.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
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
import System

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

    static func getValidPath(url: URL) -> URL? {
        let resolvedURL = url.resolvingSymlinksInPath().standardizedFileURL
        let filePath = FilePath(resolvedURL.path).lexicallyNormalized()

        let containerBasePaths = [
            URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/"),
            URL(fileURLWithPath: "/var/mobile/Containers/Data/Application/")
        ]

        for containerBasePath in containerBasePaths {
            let appContainerPath = FilePath(containerBasePath
                .resolvingSymlinksInPath()
                .standardizedFileURL.path)
                .lexicallyNormalized()

            if filePath.starts(with: appContainerPath) {
                return resolvedURL
            }
        }

        // Check if file is opened externally (outside of application)
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ee.ria.digidoc.ios") {
            let resolvedAppGroupURL = appGroupURL.resolvingSymlinksInPath()

            let normalizedURL = URL(fileURLWithPath: String(decoding: filePath))

            let resolvedAppGroupFilePath = FilePath(stringLiteral: resolvedAppGroupURL.deletingLastPathComponent().path)

            if normalizedURL != nil && resolvedAppGroupFilePath != nil {
                let isFromAppGroup = filePath.starts(with: resolvedAppGroupFilePath)

                if isFromAppGroup {
                    return normalizedURL
                }
            }
        }

        if isFileInsideMailFolder(resolvedURL) {
            return resolvedURL
        } else {
            // Check if file is opened from iCloud
            if isFileFromiCloud(fileURL: resolvedURL) {
                if !isFileDownloadedFromiCloud(fileURL: resolvedURL) {
                    printLog("File '\(resolvedURL.lastPathComponent)' from iCloud is not downloaded. Downloading...")

                    var fileLocationURL: URL? = nil

                    downloadFileFromiCloud(fileURL: resolvedURL) { downloadedFileUrl in
                        if let fileUrl = downloadedFileUrl {
                            printLog("File '\(resolvedURL.lastPathComponent)' downloaded from iCloud")
                            fileLocationURL = fileUrl
                        } else {
                            printLog("Unable to download file '\(resolvedURL.lastPathComponent)' from iCloud")
                            return
                        }
                    }
                    return fileLocationURL
                } else {
                    printLog("File '\(resolvedURL.lastPathComponent)' from iCloud is already downloaded")
                    return url
                }
            }
        }

        return nil
    }

    static func isFileFromiCloud(fileURL: URL) -> Bool {
        do {
            let urlResourceValues = try fileURL.resourceValues(forKeys: [.isUbiquitousItemKey])

            if let isUbiquitousItem = urlResourceValues.isUbiquitousItem, isUbiquitousItem {
                return true
            }
        } catch {
            printLog("Unable to check iCloud file '\(fileURL.lastPathComponent)' status: \(error.localizedDescription)")
        }

        return false
    }


    static func isFileDownloadedFromiCloud(fileURL: URL) -> Bool {
        do {
            let values = try fileURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])

            if let downloadingStatus = values.ubiquitousItemDownloadingStatus,
               downloadingStatus == .current {
                return true
            }
        } catch {
            printLog("Unable to check iCloud file '\(fileURL.lastPathComponent)' download status: \(error.localizedDescription)")
        }

        return false
    }

    static func downloadFileFromiCloud(fileURL: URL, completion: @escaping (URL?) -> Void) {
        do {
            try MoppFileManager.shared.fileManager.startDownloadingUbiquitousItem(at: fileURL)
            printLog("Downloading file '\(fileURL.lastPathComponent)' from iCloud")

            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                if isFileDownloadedFromiCloud(fileURL: fileURL) {
                    printLog("iCloud file '\(fileURL.lastPathComponent)' downloaded")
                    timer.invalidate()
                    completion(fileURL)
                }
            }
        } catch {
            printLog("Unable to start iCloud file '\(fileURL.lastPathComponent)' download: \(error.localizedDescription)")
            completion(nil)
        }
    }

    static func isFileInsideMailFolder(_ url: URL) -> Bool {
        let mailFolderPath = FilePath(stringLiteral: "/var/mobile/Library/Mail").lexicallyNormalized()
        let filePath = FilePath(stringLiteral: url.path).lexicallyNormalized()

        if filePath == mailFolderPath {
            printLog("File '\(url.lastPathComponent)' is from Mail app")
            return true
        }

        if filePath.starts(with: mailFolderPath) {
            let mailPathString = mailFolderPath.string
            let filePathString = filePath.string

            if filePathString.count == mailPathString.count {
                printLog("File '\(url.lastPathComponent)' is from Mail app")
                return true
            }

            let index = filePathString.index(filePathString.startIndex, offsetBy: mailPathString.count)
            if filePathString[index] == "/" {
                printLog("File '\(url.lastPathComponent)' is from Mail app")
                return true
            }
        }

        printLog("File '\(url.lastPathComponent)' is NOT from Mail app")

        return false
    }
}

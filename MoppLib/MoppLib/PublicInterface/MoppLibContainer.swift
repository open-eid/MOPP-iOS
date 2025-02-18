//
//  MoppLibContainer.swift
//  MoppLib
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

@objcMembers
public class MoppLibContainer: NSObject {

    public var fileName: String = ""
    public var filePath: String = ""
    public var dataFiles: [MoppLibDataFile] = []
    public var signatures: [MoppLibSignature] = []
    public var timestampTokens: [MoppLibSignature] = []

    func isSigned() -> Bool {
        return !signatures.isEmpty
    }

    func isEmpty() -> Bool {
        return dataFiles.isEmpty
    }

    public func isDdoc() -> Bool {
        return fileName.lowercased().hasSuffix(".ddoc")
    }

    func isBdoc() -> Bool {
        return fileName.lowercased().hasSuffix(".bdoc")
    }

    func isAsice() -> Bool {
        let lowerFileName = fileName.lowercased()
        return lowerFileName.hasSuffix(".asice") || lowerFileName.hasSuffix(".sce")
    }

    public func isAsics() -> Bool {
        let lowerFileName = fileName.lowercased()
        return lowerFileName.hasSuffix(".asics") || lowerFileName.hasSuffix(".scs")
    }

    func isLegacy() -> Bool {
        let lowerFileName = fileName.lowercased()
        return lowerFileName.hasSuffix(".adoc") || lowerFileName.hasSuffix(".edoc") || lowerFileName.hasSuffix(".ddoc")
    }

    public func isSignable() -> Bool {
        return isBdoc() || isAsice()
    }

    func getNextSignatureId() -> String {
        let existingIds = dataFiles.map { $0.fileId }
        var nextId = 0
        while existingIds.contains("S\(nextId)") {
            nextId += 1
        }
        return "S\(nextId)"
    }

    func fileNameWithoutExtension() -> String {
        return (fileName as NSString).deletingPathExtension
    }
}

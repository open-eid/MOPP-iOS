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

public class MoppLibContainer: NSObject {

    public var fileName: String = ""
    public var filePath: String = ""
    public var dataFiles: [MoppLibDataFile] = []
    public var signatures: [MoppLibSignature] = []

    public override init() {
        super.init()
    }

    @objc
    public init(fileName: String, filePath: String, dataFiles: [MoppLibDataFile], signatures: [MoppLibSignature]) {
        self.fileName = fileName
        self.filePath = filePath
        self.dataFiles = dataFiles
        self.signatures = signatures
        super.init()
    }

    public var isDdoc: Bool {
        fileName.lowercased().hasSuffix(".ddoc")
    }

    public var isAsics: Bool {
        let lowerFileName = fileName.lowercased()
        return lowerFileName.hasSuffix(".asics") || lowerFileName.hasSuffix(".scs")
    }

    public var isCades: Bool {
        signatures.contains { signature in
            signature.signatureFormat.lowercased().contains("cades")
        }
    }

    public var isTST: Bool {
        signatures.contains { signature in
            signature.signatureFormat.lowercased().contains("timestamptoken")
        }
    }

    public var isXades: Bool {
        signatures.contains { signature in
            signature.signatureFormat.lowercased().contains("bes")
        }
    }

    public var isSignable: Bool {
        let lowerFileName = fileName.lowercased()
        return lowerFileName.hasSuffix(".bdoc") || lowerFileName.hasSuffix(".asice") || lowerFileName.hasSuffix(".sce")
    }
}

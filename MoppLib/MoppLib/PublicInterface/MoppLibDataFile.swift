//
//  MoppLibDataFile.swift
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

@objcMembers
public class MoppLibDataFile : NSObject {
    public let fileName: String
    public let mediaType: String
    public let fileId: String
    public let fileSize: CUnsignedLong

    public init(fileName: String, mediaType: String, fileId: String, fileSize: CUnsignedLong) {
        self.fileName = fileName
        self.mediaType = mediaType
        self.fileId = fileId
        self.fileSize = fileSize
    }
}

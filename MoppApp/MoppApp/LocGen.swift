#!/usr/bin/env xcrun -sdk macosx swift

import Foundation
import Darwin

class StreamReader  {

    let encoding : String.Encoding
    let chunkSize : Int
    var fileHandle : FileHandle!
    let delimData : Data
    var buffer : Data
    var atEof : Bool

    init?(path: String, delimiter: String = "\n", encoding: String.Encoding = .utf8,
          chunkSize: Int = 4096) {

        guard let fileHandle = FileHandle(forReadingAtPath: path),
            let delimData = delimiter.data(using: encoding) else {
                return nil
        }
        self.encoding = encoding
        self.chunkSize = chunkSize
        self.fileHandle = fileHandle
        self.delimData = delimData
        self.buffer = Data(capacity: chunkSize)
        self.atEof = false
    }

    deinit {
        self.close()
    }

    /// Return next line, or nil on EOF.
    func nextLine() -> String? {
        precondition(fileHandle != nil, "Attempt to read from closed file")

        // Read data chunks from file until a line delimiter is found:
        while !atEof {
            if let range = buffer.range(of: delimData) {
                // Convert complete line (excluding the delimiter) to a string:
                let line = String(data: buffer.subdata(in: 0..<range.lowerBound), encoding: encoding)
                // Remove line (and the delimiter) from the buffer:
                buffer.removeSubrange(0..<range.upperBound)
                return line
            }
            let tmpData = fileHandle.readData(ofLength: chunkSize)
            if tmpData.count > 0 {
                buffer.append(tmpData)
            } else {
                // EOF or read error.
                atEof = true
                if buffer.count > 0 {
                    // Buffer contains last line in file (not terminated by delimiter).
                    let line = String(data: buffer as Data, encoding: encoding)
                    buffer.count = 0
                    return line
                }
            }
        }
        return nil
    }

    /// Start reading from the beginning of file.
    func rewind() -> Void {
        fileHandle.seek(toFileOffset: 0)
        buffer.count = 0
        atEof = false
    }

    /// Close the underlying file. No reading must be done after calling this method.
    func close() -> Void {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}

extension StreamReader : Sequence {
    func makeIterator() -> AnyIterator<String> {
        return AnyIterator {
            return self.nextLine()
        }
    }
}

func stringsFileKeys(path: String) -> [String]
{
    var result = [String]()
    let sr = StreamReader(path: path)
    while(true)
    {
        guard var line = sr?.nextLine() else { break }
        
        line = line.trimmingCharacters(in: .whitespaces)
        
        if line.isEmpty { continue }
        
        // Skip lines that doesn't start with double-quote character
        var index = line.index (line.startIndex, offsetBy: 0)
        if line[index] != "\"" { continue }
        
        index = line.index (line.startIndex, offsetBy: 1)
        line = String(line[index..<line.endIndex])
        index = line.index(of: "\"") ?? line.endIndex
        
        let key = String(line[line.startIndex..<index])
        
        result.append(key)
    }
    sr?.close()
    return result
}

func enumLine(key: String) -> String {
    var key = key
    let oldKey = key

    var index: String.Index
    var convertedKey = String()
    while(!key.isEmpty) {
        index = key.index(of: "-") ?? key.endIndex
        var keyPart = String(key[key.startIndex..<index])
        keyPart = keyPart.capitalized
        convertedKey.append(keyPart)
        if index != key.endIndex { index = key.index(index, offsetBy: 1) }
        key.removeSubrange(key.startIndex..<index)
    }

    return "case \(convertedKey) = \"\(oldKey)\""
}

var stringFilePaths = CommandLine.arguments[1..<CommandLine.arguments.count]

var pathToKeys = [String:[String]]()
for path in stringFilePaths {
    pathToKeys[path] = stringsFileKeys(path: path)
}

// Check keys count

var count: Int!
for (path, keys) in pathToKeys {
    if count == nil {
        count = keys.count
    } else {
        if count != keys.count {
            print("ERROR: Strings files have different key count!", path)
            exit(1)
        }
    }
}

let header = """
//
//  LocalizationKeys.swift
//  MoppApp
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

enum LocKey : String
{
    typealias RawValue = String
    
"""

print(header)

for key in pathToKeys.values.first! {
    print("    " + enumLine(key: key))
}

print("}")

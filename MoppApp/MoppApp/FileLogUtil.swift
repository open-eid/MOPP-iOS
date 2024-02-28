//
//  OneTimeLogUtil.swift
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

class FileLogUtil: LogFileGenerating {
    
    private static let DIAGNOSTICS_LOGS_FILE_NAME = "ria_digidoc_" + MoppApp.versionString + "_logs.log";
    
    static func setupAppLogging() {
        if (isLoggingEnabled() && isLoggingRunning()) {
            FileLogUtil.disableLoggingAndRemoveFiles()
        } else if (isLoggingEnabled()) {
            enableLoggingRunning()
            FileLogUtil.logToFile()
        }
    }
    
    static func isLoggingEnabled() -> Bool {
        return DefaultsHelper.isFileLoggingEnabled
    }
    
    static func enableLogging() {
        printLog("Enabling file logging")
        DefaultsHelper.isFileLoggingEnabled = true
    }
    
    static func disableLogging() {
        printLog("Disabling file logging")
        DefaultsHelper.isFileLoggingEnabled = false
    }
    
    static func isLoggingRunning() -> Bool {
        return DefaultsHelper.isFileLoggingRunning
    }
    
    static func enableLoggingRunning() {
        printLog("Enabling file logging running")
        DefaultsHelper.isFileLoggingRunning = true
    }
    
    static func disableLoggingRunning() {
        printLog("Disabling file logging running")
        DefaultsHelper.isFileLoggingRunning = false
    }
    
    static func logToFile() {
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        let cacheURL = MoppFileManager.cacheDirectory
        var logsDirectory = MoppFileManager.shared.logsDirectory()
        if !MoppFileManager.shared.directoryExists(logsDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
            } catch {
                printLog("Unable to create 'logs' directory")
                logsDirectory = cacheURL
            }
        }
        let currentDate = MoppDateFormatter().ddMMYYYY(toString: Date())
        let fileName = "\(currentDate).log"
        let logFilePath = logsDirectory.appendingPathComponent(fileName)
        freopen(logFilePath.path, "a+", stderr)
        
        printLog("DEBUG mode: Logging to file. File location: \(logFilePath.path )")
    }
    
    static func getLogFiles(logsDirURL: URL) throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: logsDirURL, includingPropertiesForKeys: nil)
    }
    
    static func getFileContents(logFile: URL) throws -> String {
        let header = "\n\n" + "===== File: " + logFile.lastPathComponent + " =====" + "\n\n";
        let fileContents = try String(contentsOf: logFile, encoding: .utf8)
        return header + fileContents
    }
    
    static func logsExist(logsDirURL: URL) -> Bool {
        if MoppFileManager.shared.directoryExists(logsDirURL.path) {
            do {
                let logFiles = try FileManager.default.contentsOfDirectory(at: logsDirURL, includingPropertiesForKeys: nil)
                return logFiles.count > 0
            } catch {
                printLog("Unable to get files at \(logsDirURL.path): \(error.localizedDescription)")
                return false
            }
        }
        
        return false
    }
    
    static func combineLogFiles() throws -> URL {
        let logsDirURL = MoppFileManager.shared.logsDirectory()
        let cacheDirURL = MoppFileManager.cacheDirectory
        if logsExist(logsDirURL: logsDirURL) {
            let combinedLogFile = logsDirURL.appendingPathComponent(DIAGNOSTICS_LOGS_FILE_NAME)
            if MoppFileManager.shared.fileExists(combinedLogFile.path) {
                MoppFileManager.shared.removeFile(withPath: combinedLogFile.path)
            }
            
            var logFiles: [URL] = []
            do {
                logFiles = try getLogFiles(logsDirURL: logsDirURL)
            } catch {
                printLog("Unable to get files from 'logs' directory")
                logFiles = try getLogFiles(logsDirURL: cacheDirURL)
            }
            
            // Create empty file
            try String().write(to: combinedLogFile, atomically: true, encoding: .utf8)
            
            for logFile in logFiles where logFile.pathExtension == "log" {
                let fileContents = try getFileContents(logFile: logFile)
                let fileHandle = try FileHandle(forWritingTo: combinedLogFile)
                fileHandle.seekToEndOfFile()
                fileHandle.write(fileContents.data(using: .utf8) ?? Data())
                fileHandle.closeFile()
            }
            
            return combinedLogFile
        }
        
        throw Exception("Could not combine log files. Cannot find logs.")
    }
    
    static func removeLogFiles() throws {
        let logsDirURL = MoppFileManager.shared.logsDirectory()
        if logsExist(logsDirURL: logsDirURL) {
            do {
                let logFiles = try getLogFiles(logsDirURL: logsDirURL)
                for logFile in logFiles {
                    MoppFileManager.shared.removeFile(withPath: logFile.path)
                }
            } catch {
                printLog("Unable to get log files. Error: \(error.localizedDescription)")
                throw error
            }
        }
        throw Exception("Could not combine log files. Cannot find logs.")
    }
    
    static func disableLoggingAndRemoveFiles() {
        disableLogging()
        disableLoggingRunning()
        do {
            try removeLogFiles()
        } catch {
            printLog("Unable to remove log files. Error: \(error.localizedDescription)")
        }
    }
}

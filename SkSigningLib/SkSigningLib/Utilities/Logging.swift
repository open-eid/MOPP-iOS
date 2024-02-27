//
//  Logging.swift
//  SkSigningLib
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

class Logging {
    
    private static let frameworkBundleID = "ee.ria.digidoc.SkSigningLib"
    
    internal static func isUsingTestMode() -> Bool {
        #if DEBUG
            let testMode: Bool = true
        #else
            let testMode: Bool = false
        #endif

        return testMode
    }
    
    internal static func isLoggingEnabled() -> Bool {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: "kIsFileLoggingEnabled") && defaults.bool(forKey: "kIsFileLoggingRunning")
    }
    
    internal static func log(forMethod: String, info: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        let message = "\(forMethod):\n" +
        "\tLog info: \(info)\n" +
        "\tFile: \(file), function: \(function), line: \(line)\n"
        
        if isUsingTestMode() {
            NSLog(message)
        } else {
            if isLoggingEnabled() {
                NSLog(message)
            }
        }
    }
    
    internal static func errorLog(forMethod: String, httpResponse: HTTPURLResponse?, error: SigningError, extraInfo: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        var logMessage: String

        guard let response = httpResponse else {
            logMessage = "\(forMethod): " +
                "\tError: \(error.localizedDescription)\n" +
                "\tError description: \(localizedError(error.errorDescription ?? "")) (\(error.errorDescription ?? "Unable to get error description"))\n" +
                "\tExtra info: \(extraInfo)\n" +
                "\tFile: \(file), function: \(function), line: \(line)\n"
            
            if isUsingTestMode() {
                NSLog(logMessage)
            } else {
                if isLoggingEnabled() {
                    NSLog(logMessage)
                }
            }
            return
        }

        logMessage = "\(forMethod) response code: \(response.statusCode)\n" +
            "\tError: \(error.localizedDescription)\n" +
            "\tError description: \(localizedError(error.errorDescription ?? "")) (\(error.errorDescription ?? "Unable to get error description"))\n" +
            "\tURL: \(response.url?.absoluteString ?? "Unable to get URL")\n" +
            "\tExtra info: \(extraInfo)\n" +
            "\tFile: \(file), function: \(function), line: \(line)\n"
        
        if isUsingTestMode() {
            NSLog(logMessage)
        } else {
            if isLoggingEnabled() {
                NSLog(logMessage)
            }
        }
    }
    
    internal static func errorLog(forMethod: String, error: Error?, extraInfo: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        var logMessage: String

        if let err = error {
            logMessage = "\(forMethod):\n" +
                "\tError: \(err.localizedDescription)\n" +
                "\tExtra info: \(extraInfo)\n" +
                "\tFile: \(file), function: \(function), line: \(line)\n"
            NSLog(logMessage)
        } else {
            logMessage = "\(forMethod):\n" +
                "\tError info: \(extraInfo)\n" +
                "\tFile: \(file), function: \(function), line: \(line)\n"
            NSLog(logMessage)
        }
        
        if isUsingTestMode() {
            NSLog(logMessage)
        } else {
            if isLoggingEnabled() {
                NSLog(logMessage)
            }
        }
    }
    
    static func localizedError(_ errorDescription: String) -> String {
        guard
            let bundlePath = Bundle(identifier: Logging.frameworkBundleID)?.bundlePath,
            let bundle = Bundle(path: bundlePath)
        else { return "Unable to get localized error description" }
        
        return NSLocalizedString(errorDescription, bundle: bundle, comment: "")
    }
}

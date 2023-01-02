//
//  Logging.swift
//  SkSigningLib
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

class Logging {
    
    private static let frameworkBundleID = "ee.ria.digidoc.SkSigningLib"
    
    internal static func log(forMethod: String, info: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        #if DEBUG
            NSLog("\(forMethod):\n" +
                  "\tLog info: \(info)\n" +
                  "\tFile: \(file), function: \(function), line: \(line)\n"
            )
        #endif
    }
    
    internal static func errorLog(forMethod: String, httpResponse: HTTPURLResponse?, error: SigningError, extraInfo: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        #if DEBUG
            guard let response = httpResponse else {
                return NSLog("\(forMethod): " +
                    "\tError: \(error.localizedDescription)\n" +
                    "\tError description: \(localizedError(error.signingErrorDescription ?? "")) (\(error.signingErrorDescription ?? "Unable to get error description"))\n" +
                    "\tExtra info: \(extraInfo)\n" +
                    "\tFile: \(file), function: \(function), line: \(line)\n"
                )
            }
            NSLog("\(forMethod) response code: \(response.statusCode)\n" +
                "\tError: \(error.localizedDescription)\n" +
                "\tError description: \(localizedError(error.signingErrorDescription ?? "")) (\(error.signingErrorDescription ?? "Unable to get error description"))\n" +
                "\tURL: \(response.url?.absoluteString ?? "Unable to get URL")\n" +
                "\tExtra info: \(extraInfo)\n" +
                "\tFile: \(file), function: \(function), line: \(line)\n"
            )
        #endif
    }
    
    internal static func errorLog(forMethod: String, error: Error?, extraInfo: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        #if DEBUG
            if let err = error {
                NSLog("\(forMethod):\n" +
                      "\tError: \(err.localizedDescription)\n" +
                      "\tExtra info: \(extraInfo)\n" +
                      "\tFile: \(file), function: \(function), line: \(line)\n"
                )
            } else {
                NSLog("\(forMethod):\n" +
                      "\tError info: \(extraInfo)\n" +
                      "\tFile: \(file), function: \(function), line: \(line)\n"
                )
            }
        #endif
    }
    
    static func localizedError(_ errorDescription: String) -> String {
        guard
            let bundlePath = Bundle(identifier: Logging.frameworkBundleID)?.bundlePath,
            let bundle = Bundle(path: bundlePath)
        else { return "Unable to get localized error description" }
        
        return NSLocalizedString(errorDescription, bundle: bundle, comment: "")
    }
}

//
//  MoppLibError.swift
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

/// MoppLibError class providing predefined NSError instances
public class MoppLibError: NSObject {
    // Mopp Lib error codes

    @objc(MoppLibErrorCode) public enum Code: Int, CustomNSError {

        case general = 10005

        case fileNameTooLong = 10017 // File name too long
        case duplicatedFilename = 10023 // Filename already exists
        case OCSPTimeSlot = 10025 // Invalid OCSP time slot
        case certRevoked = 10006

        case noInternetConnection = 10018 // No internet connection
        case sslHandshakeFailed = 10027 // SSL handshake failed
        case invalidProxySettings = 10028 // Connecting with current proxy settings failed
        case tooManyRequests = 10024 // Too many requests

        case readerProcessFailed = 10026 // Reader process failed
        case cardNotFound = 10002 // Reader is connected, but card is not detected
        case wrongPin = 10004 // Provided pin is wrong
        case pinBlocked = 10016 // User did not provide pin for action that required authentication
        case pinMatchesOldCode = 10019 // New pin must be different from old pin or puk

        public var localizedDescription: String {
            switch self {
            case .general: "Could not complete action due to unknown error"

            case .fileNameTooLong: "File name is too long"
            case .duplicatedFilename: "Filename already exists"
            case .OCSPTimeSlot: "Invalid OCSP time slot"
            case .certRevoked: "Certificate has been revoked."

            case .noInternetConnection: "Internet connection not detected."
            case .sslHandshakeFailed: "Failed to create SSL connection with host."
            case .invalidProxySettings: "Invalid proxy settings"
            case .tooManyRequests: "digidoc-service-error-too-many-requests"

            case .readerProcessFailed: "Reader process failed."
            case .cardNotFound: "ID card could not be detected in reader."
            case .wrongPin: "Wrong PIN entered"
            case .pinBlocked: "PIN blocked"
            case .pinMatchesOldCode: "New PIN must be different from old PIN."
            }
        }

        public static var errorDomain: String { "MoppLib.MoppLibError.Code" }
        public var errorCode: Int { self.rawValue }
        public var errorUserInfo: [String : Any] {
            [NSLocalizedDescriptionKey: self.localizedDescription]
        }

        public static func == (lhs: NSError, rhs: MoppLibError.Code) -> Bool {
            lhs.code == rhs.rawValue && lhs.domain == Code.errorDomain
        }

        public static func ~= (lhs: MoppLibError.Code, rhs: NSError) -> Bool {
            lhs.rawValue == rhs.code && Code.errorDomain == rhs.domain
        }
    }

    static public let kMoppLibUserInfoRetryCount: String = "kMoppLibUserInfoRetryCount"
    static public let kMoppLibUserInfoSWError: String = "kMoppLibUserInfoSWError"

    private override init() {}

    static func swError(_ sw: UInt16) -> NSError {
        error(.readerProcessFailed, userInfo: [NSLocalizedDescriptionKey: Code.wrongPin.localizedDescription,
                                                 kMoppLibUserInfoSWError: NSNumber(value: sw)])
    }

    static func wrongPinError(withRetryCount count: Int) -> NSError {
        error(.wrongPin, userInfo: [NSLocalizedDescriptionKey: Code.wrongPin.localizedDescription,
                                   kMoppLibUserInfoRetryCount: NSNumber(value: count)])
    }

    @objc public static func error(message: String) -> NSError {
        error(.general, userInfo: [NSLocalizedDescriptionKey: message])
    }

    @objc public static func error(_ code: Code) -> NSError {
        error(code, userInfo: [NSLocalizedDescriptionKey: code.localizedDescription])
    }

    /// Generic function to create an `NSError` with custom `userInfo`
    private static func error(_ code: Code, userInfo: [String: Any]?) -> NSError {
        NSError(domain: Code.errorDomain, code: code.rawValue, userInfo: userInfo)
    }
}

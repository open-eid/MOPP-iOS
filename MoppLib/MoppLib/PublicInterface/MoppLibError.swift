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

// Mopp Lib error codes

public enum MoppLibErrorCode: Int {

    case moppLibErrorCardNotFound = 10002 // Reader is connected, but card is not detected
    case moppLibErrorWrongPin = 10004 // Provided pin is wrong
    case moppLibErrorGeneral = 10005
    case moppLibErrorPinMatchesVerificationCode = 10007 // New pin must be different from old pin or puk
    case moppLibErrorIncorrectPinLength = 10008 // New pin is too short or too long
    case moppLibErrorPinTooEasy = 10009// New pin is too easy
    case moppLibErrorPinContainsInvalidCharacters = 10010 // Pin contains invalid characters. Only numbers are allowed
    case moppLibErrorPinBlocked = 10016 // User did not provide pin for action that required authentication
    case moppLibErrorFileNameTooLong = 10017 // File name too long
    case moppLibErrorNoInternetConnection = 10018 // No internet connection
    case moppLibErrorPinMatchesOldCode = 10019 // New pin must be different from old pin or puk
    case moppLibErrorRestrictedApi = 10021 // Restricted API. Some functionality is not available for third-party apps
    case moppLibErrorDuplicatedFilename = 10023 // Filename already exists
    case moppLibErrorTooManyRequests = 10024 // Too many requests
    case moppLibErrorOCSPTimeSlot = 10025 // Invalid OCSP time slot
    case moppLibErrorReaderProcessFailed = 10026 // Reader process failed
    case moppLibErrorSslHandshakeFailed = 10027 // SSL handshake failed
    case moppLibErrorInvalidProxySettings = 10028 // Connecting with current proxy settings failed

};

/// MoppLibError class providing predefined NSError instances
@objcMembers
public class MoppLibError: NSObject {
    /// Error domain for MoppLib errors
    static let MoppLibErrorDomain = "MoppLibError"
    static public let kMoppLibUserInfoRetryCount: String = "kMoppLibUserInfoRetryCount"

    private override init() {}

    static func readerProcessFailedError() -> NSError {
        return error(code: .moppLibErrorReaderProcessFailed, message: "Reader process failed.")
    }

    static func cardNotFoundError() -> NSError {
        return error(code: .moppLibErrorCardNotFound, message: "ID card could not be detected in reader.")
    }

    static func wrongPinError(withRetryCount count: Int) -> NSError {
        return error(code: .moppLibErrorWrongPin, userInfo: [kMoppLibUserInfoRetryCount: NSNumber(value: count)])
    }

    public static func generalError() -> NSError {
        return error(code: .moppLibErrorGeneral, message: "Could not complete action due to unknown error")
    }

    public static func pinBlockedError() -> NSError {
        return error(code: .moppLibErrorPinBlocked, userInfo: nil)
    }

    static func pinMatchesVerificationCodeError() -> NSError {
        return error(code: .moppLibErrorPinMatchesVerificationCode, message: "New PIN must be different from verification code.")
    }

    static func pinMatchesOldCodeError() -> NSError {
        return error(code: .moppLibErrorPinMatchesOldCode, message: "New PIN must be different from old PIN.")
    }

    static func incorrectPinLengthError() -> NSError {
        return error(code: .moppLibErrorIncorrectPinLength, message: "PIN length didn't pass validation. Make sure minimum and maximum length requirements are met.")
    }

    static func tooEasyPinError() -> NSError {
        return error(code: .moppLibErrorPinTooEasy, message: "New PIN code is too easy.")
    }

    static func pinContainsInvalidCharactersError() -> NSError {
        return error(code: .moppLibErrorPinContainsInvalidCharacters, message: "New PIN contains invalid characters.")
    }

    public static func fileNameTooLongError() -> NSError {
        return error(code: .moppLibErrorFileNameTooLong, message: "File name is too long")
    }

    public static func noInternetConnectionError() -> NSError {
        return error(code: .moppLibErrorNoInternetConnection, message: "Internet connection not detected.")
    }

    public static func sslHandshakeError() -> NSError {
        return error(code: .moppLibErrorSslHandshakeFailed, message: "Failed to create SSL connection with host.")
    }

    static func restrictedAPIError() -> NSError {
        return error(code: .moppLibErrorRestrictedApi, message: "This API method is not supported on third-party applications.")
    }

    public static func duplicatedFilenameError() -> NSError {
        return error(code: .moppLibErrorDuplicatedFilename, message: "Filename already exists")
    }

    public static func tooManyRequests() -> NSError {
        return error(code: .moppLibErrorTooManyRequests, message: "digidoc-service-error-too-many-requests")
    }

    public static func ocspTimeSlotError() -> NSError {
        return error(code: .moppLibErrorOCSPTimeSlot, message: "Invalid OCSP time slot")
    }

    public static func invalidProxySettingsError() -> NSError {
        return error(code: .moppLibErrorInvalidProxySettings, message: "Invalid proxy settings")
    }

    /// Generic function to create an `NSError` with a message
    private static func error(code: MoppLibErrorCode, message: String) -> NSError {
        return error(code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }

    /// Generic function to create an `NSError` with custom `userInfo`
    private static func error(code: MoppLibErrorCode, userInfo: [String: Any]?) -> NSError {
        return NSError(domain: MoppLibErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
}

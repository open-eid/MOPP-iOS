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
@objcMembers
public class MoppLibError: NSObject {
    /// Error domain for MoppLib errors
    static let MoppLibErrorDomain = "MoppLibError"

    public static func readerNotFoundError() -> NSError {
        return error(code: .moppLibErrorReaderNotFound, message: "Reader is not connected to the device.")
    }

    public static func readerProcessFailedError() -> NSError {
        return error(code: .moppLibErrorReaderProcessFailed, message: "Reader process failed.")
    }

    public static func readerSelectionCanceledError() -> NSError {
        return error(code: .moppLibErrorReaderSelectionCanceled, message: "User canceled reader selection.")
    }

    public static func cardNotFoundError() -> NSError {
        return error(code: .moppLibErrorCardNotFound, message: "ID card could not be detected in reader.")
    }

    public static func cardVersionUnknownError() -> NSError {
        return error(code: .moppLibErrorCardVersionUnknown, message: "Card version could not be detected.")
    }

    public static func wrongPinError(withRetryCount count: Int) -> NSError {
        return error(code: .moppLibErrorWrongPin, userInfo: [kMoppLibUserInfoRetryCount: NSNumber(value: count)])
    }

    public static func generalError() -> NSError {
        return error(code: .moppLibErrorGeneral, message: "Could not complete action due to unknown error")
    }

    public static func invalidPinError() -> NSError {
        return error(code: .moppLibErrorInvalidPin, message: "Invalid PIN")
    }

    public static func pinBlockedError() -> NSError {
        return error(code: .moppLibErrorPinBlocked, userInfo: nil)
    }

    public static func pinMatchesVerificationCodeError() -> NSError {
        return error(code: .moppLibErrorPinMatchesVerificationCode, message: "New PIN must be different from verification code.")
    }

    public static func pinMatchesOldCodeError() -> NSError {
        return error(code: .moppLibErrorPinMatchesOldCode, message: "New PIN must be different from old PIN.")
    }

    public static func incorrectPinLengthError() -> NSError {
        return error(code: .moppLibErrorIncorrectPinLength, message: "PIN length didn't pass validation. Make sure minimum and maximum length requirements are met.")
    }

    public static func tooEasyPinError() -> NSError {
        return error(code: .moppLibErrorPinTooEasy, message: "New PIN code is too easy.")
    }

    public static func pinContainsInvalidCharactersError() -> NSError {
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

    public static func restrictedAPIError() -> NSError {
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

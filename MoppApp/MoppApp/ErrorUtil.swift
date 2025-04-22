//
//  ErrorUtil.swift
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

import SkSigningLib

class ErrorUtil {

    static func generateError(signingError: any Error, signingType: SigningType) {
        let nsError = signingError as NSError
        switch MoppLibError.Code(rawValue: nsError.code) {
        case .certRevoked:
            generateError(signingError: .certificateRevoked)
        case .OCSPTimeSlot:
            generateError(signingError: .ocspInvalidTimeSlot)
        case .tooManyRequests:
            generateError(signingError: .tooManyRequests(signingMethod: signingType.rawValue))
        case .sslHandshakeFailed:
            generateError(signingError: .invalidSSLCert)
        case .invalidProxySettings:
            generateError(signingError: .invalidProxySettings)
        case .noInternetConnection:
            generateError(signingError: .noResponseError)
        case .pinBlocked:
            generateError(signingError: L(.pin2BlockedAlert))
        case .readerProcessFailed:
            generateError(signingError: .empty, details: L(.cardReaderStateReaderProcessFailed))
        default:
            generateError(signingError: .empty, details: MessageUtil.errorMessageWithDetails(details: nsError.localizedDescription))
        }
    }

    static func generateError(signingError: SigningError, details: String = "") -> Void {
        let error = NSError(domain: "SkSigningLib", code: 10, userInfo: [NSLocalizedDescriptionKey: signingError, NSLocalizedFailureReasonErrorKey: details])
        return self.errorResult(error: error)
    }
    
    static func generateError(signingError: String, details: String = "") -> Void {
        let error = NSError(domain: "SkSigningLib", code: 10, userInfo: [NSLocalizedDescriptionKey: signingError, NSLocalizedFailureReasonErrorKey: details])
        return self.errorResult(error: error)
    }
    
    static func errorResult(error: Error) -> Void {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .errorNotificationName, object: nil, userInfo: [kErrorKey: error])
        }
    }
}

//
//  MobileIDError.swift
//  SkSigningLib
//
/*
 * Copyright 2020 Riigi Infosüsteemide Amet
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

public enum MobileIDError: Error {
    
    // MARK: General Errors
    case invalidURL
    case noResponseError
    case generalError
    
    // MARK: Response Errors
    case notFound
    case notActive
    
    // MARK: Service Errors
    case parameterNameNull
    case userAuthorizationFailed
    case methodNotAllowed
    case internalError
    case hashLengthInvalid
    case hashEncodingInvalid
    case sessionIdMissing
    case sessionIdNotFound
    
    // MARK: Session Status Errors
    case timeout
    case notMidClient
    case userCancelled
    case signatureHashMismatch
    case phoneAbsent
    case deliveryError
    case simError
}

// MARK: MobileIDError mobileIDErrorDescription Extension
extension MobileIDError: LocalizedError {
    public var mobileIDErrorDescription: String? {
        switch self {
        case .parameterNameNull:
            return NSLocalizedString("Parameter names cannot be empty", comment: "")
        case .invalidURL:
            return NSLocalizedString("Invalid URL", comment: "")
        case .noResponseError:
            return NSLocalizedString("No response", comment: "")
        case .generalError:
            return NSLocalizedString("Unknown error", comment: "")
        case .notFound:
            return NSLocalizedString("Not found.", comment: "")
        case .notActive:
            return NSLocalizedString("Not active", comment: "")
        case .userAuthorizationFailed:
            return NSLocalizedString("Failed to authorize user", comment: "")
        case .methodNotAllowed:
            return NSLocalizedString("Method not allowed", comment: "")
        case .internalError:
            return NSLocalizedString("Internal Server Error", comment: "")
        case .hashLengthInvalid:
            return NSLocalizedString("Hash length invalid", comment: "")
        case .hashEncodingInvalid:
            return NSLocalizedString("Hash encoding invalid", comment: "")
        case .sessionIdMissing:
            return NSLocalizedString("Session ID missing", comment: "")
        case .sessionIdNotFound:
            return NSLocalizedString("Session ID not found", comment: "")
        case .timeout:
            return NSLocalizedString("Session timeout", comment: "")
        case .notMidClient:
            return NSLocalizedString("Not MID Client", comment: "")
        case .userCancelled:
            return NSLocalizedString("User cancelled", comment: "")
        case .signatureHashMismatch:
            return NSLocalizedString("Signature hash mismatch", comment: "")
        case .phoneAbsent:
            return NSLocalizedString("Phone absent", comment: "")
        case .deliveryError:
            return NSLocalizedString("Delivery error", comment: "")
        case .simError:
            return NSLocalizedString("SIM error", comment: "")
        }
    }
}

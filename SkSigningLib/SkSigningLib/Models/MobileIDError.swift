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

public enum MobileIDError: String, Error {
    
    // MARK: General Errors
    case invalidURL
    case noResponseError
    case generalError
    case invalidSSLCert
    
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
    case tooManyRequests
}

// MARK: MobileIDError mobileIDErrorDescription Extension
extension MobileIDError: LocalizedError {
    public var mobileIDErrorDescription: String? {
        switch self {
        case .parameterNameNull:
            return NSLocalizedString("digidoc-service-error-incorrect-parameters", comment: "")
        case .invalidURL:
            return NSLocalizedString("Invalid URL", comment: "")
        case .noResponseError:
            return NSLocalizedString("digidoc-service-error-no-response", comment: "")
        case .generalError:
            return NSLocalizedString("digidoc-service-error-general", comment: "")
        case .notFound:
            return NSLocalizedString("digidoc-service-error-not-mobile-id-user", comment: "")
        case .notActive:
            return NSLocalizedString("digidoc-service-error-not-mobile-id-user", comment: "")
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
            return NSLocalizedString("digidoc-service-error-timeout", comment: "")
        case .notMidClient:
            return NSLocalizedString("digidoc-service-error-not-mobile-id-user", comment: "")
        case .userCancelled:
            return NSLocalizedString("digidoc-service-error-user-cancelled", comment: "")
        case .signatureHashMismatch:
            return NSLocalizedString("digidoc-service-error-signature-hash-mismatch", comment: "")
        case .phoneAbsent:
            return NSLocalizedString("digidoc-service-error-phone-absent", comment: "")
        case .deliveryError:
            return NSLocalizedString("digidoc-service-error-delivery-error", comment: "")
        case .simError:
            return NSLocalizedString("digidoc-service-error-sim-error", comment: "")
        case .tooManyRequests:
            return NSLocalizedString("digidoc-service-error-too-many-requests", comment: "")
        case .invalidSSLCert:
            return NSLocalizedString("digidoc-service-error-invalid-ssl-cert", comment: "")
        }
    }
}

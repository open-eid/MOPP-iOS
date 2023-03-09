//
//  SigningError.swift
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

public enum SigningError: String, Error {
    
    // MARK: General
    case empty
    case cancelled
    
    // MARK: General Errors
    case invalidURL
    case noResponseError
    case generalError
    case generalSignatureAddingError
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
    case exceededUnsuccessfulRequests
    
    // MARK: Session Status Errors
    case timeout
    case notMidClient
    case userCancelled
    case interactionNotSupported
    case signatureHashMismatch
    case phoneAbsent
    case deliveryError
    case simError
    case tooManyRequests
    case midInvalidAccessRights
    case sidInvalidAccessRights
    case ocspInvalidTimeSlot
    case certificateRevoked
    case technicalError

    // MARK: Smart-ID Session Status Errors
    case wrongVC
    case documentUnusable
    case notQualified
    case oldApi
    case underMaintenance
    case forbidden
    case accountNotFoundOrTimeout
}

// MARK: SigningError signingErrorDescription Extension
extension SigningError: LocalizedError {
    public var signingErrorDescription: String? {
        switch self {
        case .empty:
            return NSLocalizedString("", comment: "")
        case .cancelled:
            return NSLocalizedString("Signing cancelled", comment: "")
        case .parameterNameNull:
            return NSLocalizedString("mid-rest-error-incorrect-parameters", comment: "")
        case .invalidURL:
            return NSLocalizedString("Invalid URL", comment: "")
        case .noResponseError:
            return NSLocalizedString("mid-rest-error-no-response", comment: "")
        case .generalError:
            return NSLocalizedString("mid-rest-error-general", comment: "")
        case .notFound:
            return NSLocalizedString("mid-rest-error-not-mobile-id-user", comment: "")
        case .notActive:
            return NSLocalizedString("mid-rest-error-not-mobile-id-user", comment: "")
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
            return NSLocalizedString("mid-rest-error-timeout", comment: "")
        case .notMidClient:
            return NSLocalizedString("mid-rest-error-not-mobile-id-user", comment: "")
        case .userCancelled:
            return NSLocalizedString("mid-rest-error-user-cancelled", comment: "")
        case .signatureHashMismatch:
            return NSLocalizedString("mid-rest-error-signature-hash-mismatch", comment: "")
        case .phoneAbsent:
            return NSLocalizedString("mid-rest-error-phone-absent", comment: "")
        case .deliveryError:
            return NSLocalizedString("mid-rest-error-delivery-error", comment: "")
        case .simError:
            return NSLocalizedString("mid-rest-error-sim-error", comment: "")
        case .tooManyRequests:
            return NSLocalizedString("mid-rest-error-too-many-requests", comment: "")
        case .invalidSSLCert:
            return NSLocalizedString("mid-rest-error-invalid-ssl-cert", comment: "")
        case .wrongVC:
            return NSLocalizedString("sid-rest-error-wrong-vc", comment: "")
        case .documentUnusable:
            return NSLocalizedString("sid-rest-error-document-unusable", comment: "")
        case .notQualified:
            return NSLocalizedString("sid-rest-error-not-qualified", comment: "")
        case .oldApi:
            return NSLocalizedString("sid-rest-error-old-api", comment: "")
        case .underMaintenance:
            return NSLocalizedString("sid-rest-error-under-maintenance", comment: "")
        case .forbidden:
            return NSLocalizedString("sid-rest-error-forbidden", comment: "")
        case .accountNotFoundOrTimeout:
            return NSLocalizedString("sid-rest-error-account-not-found-or-timeout", comment: "")
        case .exceededUnsuccessfulRequests:
            return NSLocalizedString("mid-rest-error-exceeded-unsuccessful-requests", comment: "")
        case .midInvalidAccessRights:
            return NSLocalizedString("mid-rest-error-invalid-access-rights", comment: "")
        case .sidInvalidAccessRights:
            return NSLocalizedString("sid-rest-error-invalid-access-rights", comment: "")
        case .ocspInvalidTimeSlot:
            return NSLocalizedString("mid-rest-error-ocsp-invalid-time-slot", comment: "")
        case .certificateRevoked:
            return NSLocalizedString("sid-rest-error-certificate-revoked", comment: "")
        case .generalSignatureAddingError:
            return NSLocalizedString("general-signature-adding-error", comment: "")
        case .technicalError:
            return NSLocalizedString("mid-rest-error-technical-error", comment: "")
        case .interactionNotSupported:
            return NSLocalizedString("sid-interaction-not-supported-error", comment: "")
        }
    }
}

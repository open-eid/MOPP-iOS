//
//  SigningError.swift
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

public enum SigningError: Error, Equatable {

    // MARK: General
    case empty, cancelled, nfcCancelled
    
    // MARK: General Errors
    case invalidURL, noResponseError, generalError, generalSignatureAddingError, invalidSSLCert
    
    // MARK: Response Errors
    case notFound, notActive
    
    // MARK: Service Errors
    case parameterNameNull, userAuthorizationFailed, methodNotAllowed, internalError
    case hashLengthInvalid, hashEncodingInvalid, sessionIdMissing, sessionIdNotFound
    case exceededUnsuccessfulRequests
    
    // MARK: Session Status Errors
    case timeout, notMidClient, userCancelled, interactionNotSupported, signatureHashMismatch
    case phoneAbsent, deliveryError, simError, tooManyRequests(signingMethod: String)
    case midInvalidAccessRights, sidInvalidAccessRights, ocspInvalidTimeSlot, certificateRevoked
    case technicalError

    // MARK: Smart-ID Session Status Errors
    case wrongVC, documentUnusable, notQualified, oldApi, underMaintenance, forbidden
    case accountNotFoundOrTimeout

    public init?(rawValue: String) {
        switch rawValue {
        case "empty":
            self = .empty
        case "cancelled":
            self = .cancelled
        case "nfcCancelled":
            self = .nfcCancelled
        case "invalidURL":
            self = .invalidURL
        case "noResponseError":
            self = .noResponseError
        case "generalError":
            self = .generalError
        case "generalSignatureAddingError":
            self = .generalSignatureAddingError
        case "invalidSSLCert":
            self = .invalidSSLCert
        case "notFound":
            self = .notFound
        case "notActive":
            self = .notActive
        case "parameterNameNull":
            self = .parameterNameNull
        case "userAuthorizationFailed":
            self = .userAuthorizationFailed
        case "methodNotAllowed":
            self = .methodNotAllowed
        case "internalError":
            self = .internalError
        case "hashLengthInvalid":
            self = .hashLengthInvalid
        case "hashEncodingInvalid":
            self = .hashEncodingInvalid
        case "sessionIdMissing":
            self = .sessionIdMissing
        case "sessionIdNotFound":
            self = .sessionIdNotFound
        case "exceededUnsuccessfulRequests":
            self = .exceededUnsuccessfulRequests
        case "timeout":
            self = .timeout
        case "notMidClient":
            self = .notMidClient
        case "userCancelled":
            self = .userCancelled
        case "interactionNotSupported":
            self = .interactionNotSupported
        case "signatureHashMismatch":
            self = .signatureHashMismatch
        case "phoneAbsent":
            self = .phoneAbsent
        case "deliveryError":
            self = .deliveryError
        case "simError":
            self = .simError
        case let stringValue where stringValue.hasPrefix("tooManyRequests(") && stringValue.hasSuffix(")"):
            let signingMethod = stringValue
                .dropFirst("tooManyRequests(".count)
                .dropLast(")".count)
            self = .tooManyRequests(signingMethod: String(signingMethod))
        case "midInvalidAccessRights":
            self = .midInvalidAccessRights
        case "sidInvalidAccessRights":
            self = .sidInvalidAccessRights
        case "ocspInvalidTimeSlot":
            self = .ocspInvalidTimeSlot
        case "certificateRevoked":
            self = .certificateRevoked
        case "technicalError":
            self = .technicalError
        case "wrongVC":
            self = .wrongVC
        case "documentUnusable":
            self = .documentUnusable
        case "notQualified":
            self = .notQualified
        case "oldApi":
            self = .oldApi
        case "underMaintenance":
            self = .underMaintenance
        case "forbidden":
            self = .forbidden
        case "accountNotFoundOrTimeout":
            self = .accountNotFoundOrTimeout
        default:
            return nil // Return nil for unknown cases
        }
    }
}

// MARK: SigningError signingErrorDescription Extension
extension SigningError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .empty:
            return NSLocalizedString("", comment: "")
        case .cancelled:
            return NSLocalizedString("Signing cancelled", comment: "")
        case .nfcCancelled:
            return NSLocalizedString("NFC signing cancelled", comment: "")
        case .parameterNameNull:
            return NSLocalizedString("mid-rest-error-incorrect-parameters", comment: "")
        case .invalidURL:
            return NSLocalizedString("Invalid URL", comment: "")
        case .noResponseError:
            return NSLocalizedString("mid-rest-error-no-response", comment: "")
        case .generalError:
            return NSLocalizedString("mid-rest-error-general", comment: "")
        case .notFound, .notActive:
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
        case .tooManyRequests(let signingMethod):
            return signingMethod
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


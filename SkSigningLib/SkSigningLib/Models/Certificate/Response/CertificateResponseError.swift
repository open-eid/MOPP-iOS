//
//  ResponseError.swift
//  SkSigningLib
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

public enum CertificateResponseError: Error {
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
}

// MARK: HTTPURLResponse Service errorCode Extension
extension HTTPURLResponse {
    var errorCode: CertificateResponseError? {
        switch self.statusCode {
        case 400:
            return .parameterNameNull
        case 401:
            return .userAuthorizationFailed
        case 405:
            return .methodNotAllowed
        case 500:
            return .internalError
        default:
            break
        }
        
        return .generalError
    }
    
}

// MARK: CertificateResponseError Service errorDescription Extension
extension CertificateResponseError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .parameterNameNull:
            return NSLocalizedString("400", comment: "")
        case .invalidURL:
            return NSLocalizedString("A user-friendly description of the error.", comment: "My error")
        case .noResponseError:
            return NSLocalizedString("A user-friendly description of the error.", comment: "My error")
        case .generalError:
            return NSLocalizedString("A user-friendly description of the error.", comment: "My error")
        case .notFound:
            return NSLocalizedString("A user-friendly description of the error.", comment: "My error")
        case .notActive:
            return NSLocalizedString("A user-friendly description of the error.", comment: "My error")
        case .userAuthorizationFailed:
            return NSLocalizedString("Failed to authorize user.", comment: "401")
        case .methodNotAllowed:
            return NSLocalizedString("A user-friendly description of the error.", comment: "My error")
        case .internalError:
            return NSLocalizedString("A user-friendly description of the error.", comment: "My error")
        }
    }
}

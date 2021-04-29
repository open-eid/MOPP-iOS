//
//  Session.swift
//  MoppApp
//
/*
  * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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
import SkSigningLib

class Session {
    static let shared: Session = Session()
    
    func getSession(baseUrl: String, uuid: String, phoneNumber: String, nationalIdentityNumber: String, hash: String, hashType: String, language: String, trustedCertificates: [String]?, completionHandler: @escaping (Result<SessionResponse, SigningError>) -> Void) -> Void {
        do {
            _ = try RequestSession.shared.getSession(baseUrl: baseUrl, requestParameters: SessionRequestParameters(relyingPartyName: kRelyingPartyName, relyingPartyUUID: uuid, phoneNumber: "+\(phoneNumber)", nationalIdentityNumber: nationalIdentityNumber, hash: hash, hashType: hashType, language: language, displayText: L(.simToolkitSignDocumentTitle), displayTextFormat: kDisplayTextFormat), trustedCertificates: trustedCertificates) { (sessionResult) in
                
                switch sessionResult {
                case .success(let response):
                    NSLog("\nReceived Session (session ID redacted): \(response.sessionID?.prefix(13) ?? "-")\n")
                    completionHandler(.success(response))
                case .failure(let sessionError):
                    NSLog("Getting session error: \(sessionError.signingErrorDescription ?? sessionError.rawValue)")
                    return completionHandler(.failure(sessionError))
                }
            }
        } catch let error {
            NSLog("Error occurred while getting session: \(error.localizedDescription)")
            return completionHandler(.failure(.generalError))
        }
    }
}

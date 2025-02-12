//
//  Session.swift
//  MoppApp
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
import SkSigningLib

class Session {
    static let shared: Session = Session()
    
    func getSession(baseUrl: String, uuid: String, phoneNumber: String, nationalIdentityNumber: String, hash: Data, hashType: String, language: String, trustedCertificates: [String]?, completionHandler: @escaping (Result<SessionResponse, SigningError>) -> Void) -> Void {
        do {
            _ = try RequestSession.shared.getSession(baseUrl: baseUrl, requestParameters: SessionRequestParameters(relyingPartyName: kRelyingPartyName, relyingPartyUUID: uuid, phoneNumber: "+\(phoneNumber)", nationalIdentityNumber: nationalIdentityNumber, hash: hash, hashType: hashType, language: language, displayText: L(.simToolkitSignDocumentTitle).asUnicode, displayTextFormat: DefaultsHelper.moppLanguageID == "ru" ? kAlternativeDisplayTextFormat : kDisplayTextFormat), trustedCertificates: trustedCertificates, manualProxyConf: ManualProxy.getManualProxyConfiguration()) { (sessionResult) in
                
                switch sessionResult {
                case .success(let response):
                    printLog("\nReceived Session (session ID): \(response.sessionID ?? "Unable to display session ID")\n")
                    completionHandler(.success(response))
                case .failure(let sessionError):
                    printLog("Getting session error: \(SkSigningLib_LocalizedString((sessionError.errorDescription ?? sessionError.errorDescription) ?? "Error not available"))")
                    return completionHandler(.failure(sessionError))
                }
            }
        } catch let error {
            printLog("Error occurred while getting session: \(error.localizedDescription)")
            return completionHandler(.failure(.generalError))
        }
    }
}

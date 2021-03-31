/*
 * MoppApp - SmartIDSignature.swift
 * Copyright 2020 Riigi Infosüsteemi Amet
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
import SwiftyRSA.NSData_SHA

class SmartIDSignature {

    static let shared: SmartIDSignature = SmartIDSignature()

    func createSmartIDSignature(country: String, nationalIdentityNumber: String, containerPath: String, hashType: String) -> Void {
        let baseUrl = DefaultsHelper.rpUuid.isEmpty ? Configuration.getConfiguration().SIDPROXYURL : Configuration.getConfiguration().SIDSKURL
        let uuid = DefaultsHelper.rpUuid.isEmpty ? kRelyingPartyUUID : DefaultsHelper.rpUuid
        let certBundle = Configuration.getConfiguration().CERTBUNDLE
        let backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Smart-ID")
        let certparams = SIDCertificateRequestParameters(relyingPartyName: kRelyingPartyName, relyingPartyUUID: uuid)
        let errorHandler: (MobileIDError, String) -> Void = { error, log in
            UIApplication.shared.endBackgroundTask(backgroundTask)
            NSLog("\(log): \(error.mobileIDErrorDescription ?? error.rawValue)")
            self.generateError(error: error)
        }
        getCertificate(baseUrl: baseUrl, country: country, nationalIdentityNumber: nationalIdentityNumber, requestParameters: certparams, containerPath: containerPath, trustedCertificates: certBundle, errorHandler: errorHandler) { documentNumber, cert, hash in
            let signparams = SIDSignatureRequestParameters(relyingPartyName: kRelyingPartyName, relyingPartyUUID: uuid, hash: hash, hashType: hashType, displayText: L(.simToolkitSignDocumentTitle), vcChoice: true)
            self.getSignature(baseUrl: baseUrl, documentNumber: documentNumber, requestParameters: signparams, trustedCertificates: certBundle, errorHandler: errorHandler) { signatureValue in
                self.validateSignature(cert: cert, signatureValue: signatureValue)
                UIApplication.shared.endBackgroundTask(backgroundTask)
            }
        }
    }

    private func getCertificate(baseUrl: String, country: String, nationalIdentityNumber: String, requestParameters: SIDCertificateRequestParameters, containerPath: String, trustedCertificates: [String]?, errorHandler: @escaping (MobileIDError, String) -> Void, completionHandler: @escaping (String, String, String) -> Void) {
        NSLog("Getting certificate...")
        SIDRequest.shared.getCertificate(baseUrl: baseUrl, country: country, nationalIdentityNumber: nationalIdentityNumber, requestParameters: requestParameters, trustedCertificates: trustedCertificates) { result in
            switch result {
            case .success(let response):
                NSLog("Received Certificate (session ID redacted): \(response.sessionID.prefix(13))")
                self.getSessionStatus(baseUrl: baseUrl, sessionId: response.sessionID, trustedCertificates: trustedCertificates, notification: self.selectAccount) { result in
                    switch result {
                    case .success(let sessionStatus):
                        guard let documentNumber = sessionStatus.result?.documentNumber else {
                            return errorHandler(.generalError, "Unable to get documentNumber value")
                        }
                        guard let certificateValue = sessionStatus.cert?.value else {
                            return errorHandler(.generalError, "Unable to get certificate value")
                        }
                        guard let hash = self.setupControlCode(certificateValue: certificateValue, containerPath: containerPath) else {
                            return errorHandler(.generalError, "Error getting hash. Is 'cert' empty: \(certificateValue.isEmpty). ContainerPath: \(containerPath)")
                        }
                        completionHandler(documentNumber, certificateValue, hash)
                    case .failure(let error):
                        errorHandler(error, "Unable to get certificate status")
                    }
                }
            case .failure(let error):
                errorHandler(error, "Getting certificate error")
            }
        }
    }

    private func getSignature(baseUrl: String, documentNumber: String, requestParameters: SIDSignatureRequestParameters, trustedCertificates: [String]?, errorHandler: @escaping (MobileIDError, String) -> Void, completionHandler: @escaping (String) -> Void) {
        NSLog("Getting signature...")
        SIDRequest.shared.getSignature(baseUrl: baseUrl, documentNumber: documentNumber, requestParameters: requestParameters, trustedCertificates: trustedCertificates) { result in
            switch result {
            case .success(let response):
                NSLog("Received Signature (session ID redacted): \(response.sessionID.prefix(13))")
                self.getSessionStatus(baseUrl: baseUrl, sessionId: response.sessionID, trustedCertificates: trustedCertificates) { result in
                    switch result {
                    case .success(let sessionStatus):
                        guard let signatureValue = sessionStatus.signature?.value else {
                            return errorHandler(.generalError, "Unable to get signature value")
                        }
                        completionHandler(signatureValue)
                    case .failure(let error):
                        errorHandler(error, "Unable to get signature status")
                    }
                }
            case .failure(let error):
                errorHandler(error, "Getting signature error")
            }
        }
    }

    private func getSessionStatus(baseUrl: String, sessionId: String, trustedCertificates: [String]?, notification: @escaping () -> Void = {}, completionHandler: @escaping (Result<SIDSessionStatusResponse, MobileIDError>) -> Void) {
        NSLog("Requesting session status...")
        SIDRequest.shared.getSessionStatus(baseUrl: baseUrl, sessionId: sessionId, timeoutMs: kDefaultTimeoutMs, trustedCertificates: trustedCertificates) { result in
            switch result {
            case .success(let sessionStatus):
                NSLog("Session status \(sessionStatus.state.rawValue)")
                switch sessionStatus.state {
                case .RUNNING:
                    notification()
                    self.getSessionStatus(baseUrl: baseUrl, sessionId: sessionId, trustedCertificates: trustedCertificates, completionHandler: completionHandler);
                case .COMPLETE:
                    guard let sessionStatusResult = sessionStatus.result else {
                        return completionHandler(.failure(.generalError))
                    }
                    NSLog("EndResult: \(sessionStatusResult.endResult.rawValue)")
                    if sessionStatusResult.endResult != .OK {
                        return completionHandler(.failure({
                            switch sessionStatusResult.endResult {
                            case .TIMEOUT: return .sidTimeout
                            case .USER_REFUSED: return .userCancelled
                            case .WRONG_VC: return .wrongVC
                            case .DOCUMENT_UNUSABLE: return .documentUnusable
                            default: return .generalError
                            }
                        }()))
                    }
                    completionHandler(.success(sessionStatus))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    private func selectAccount() -> Void {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .selectSmartIDAccountNotificationName, object: nil, userInfo: nil)
        }
    }
    
    private func validateSignature(cert: String, signatureValue: String) -> Void {
        NSLog("\nValidating signature...\n")
        MoppLibManager.isSignatureValid(cert, signatureValue: signatureValue, success: { (_) in
            NSLog("\nSuccessfully validated signature!\n")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .signatureAddedToContainerNotificationName,
                    object: nil,
                    userInfo: nil)
            }
        }, failure: { (error: Error?) in
            NSLog("\nError validating signature. Error: \(error?.localizedDescription ?? "Unable to display error")\n")
            guard let error = error, let err = error as NSError? else {
                self.generateError(error: .generalError)
                return
            }
            
            if err.code == 5 || err.code == 6 {
                NSLog(err.domain)
                self.generateError(error: .certificateRevoked)
                return
            } else if err.code == 7 {
                NSLog(err.domain)
                self.generateError(error: .ocspInvalidTimeSlot)
                return
            }
            
            return self.generateError(error: .generalError)
        })
    }

    private func setupControlCode(certificateValue: String, containerPath: String) -> String? {
        guard let hash = MoppLibManager.prepareSignature(certificateValue, containerPath: containerPath) else {
            return nil
        }
        let digest = (Data(base64Encoded: hash)! as NSData).swiftyRSASHA256()
        let code = UInt16(digest[digest.count - 2]) << 8 | UInt16(digest[digest.count - 1])
        let challengeId = String(format: "%04d", (code % 10000))
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .createSignatureNotificationName,
                object: nil,
                userInfo: [kKeySmartIDChallengeKey: challengeId]
            )
        }
        return hash
    }

    private func generateError(error: MobileIDError) -> Void {
        let error = NSError(domain: "SkSigningLib", code: 10, userInfo: [NSLocalizedDescriptionKey: error])
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .errorNotificationName, object: nil, userInfo: [kErrorKey: error])
        }
    }
}

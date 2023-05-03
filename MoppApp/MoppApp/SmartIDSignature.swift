/*
 * MoppApp - SmartIDSignature.swift
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
import SkSigningLib
import CryptoKit

class SmartIDSignature {

    static let shared: SmartIDSignature = SmartIDSignature()

    func createSmartIDSignature(country: String, nationalIdentityNumber: String, containerPath: String, hashType: String) -> Void {
        var baseUrl = DefaultsHelper.rpUuid.isEmpty ? Configuration.getConfiguration().SIDV2PROXYURL : Configuration.getConfiguration().SIDV2SKURL
        if baseUrl.isEmpty {
            baseUrl = DefaultsHelper.rpUuid.isEmpty ? Configuration.getConfiguration().SIDPROXYURL : Configuration.getConfiguration().SIDSKURL
        }
        let uuid = DefaultsHelper.rpUuid.isEmpty ? kRelyingPartyUUID : DefaultsHelper.rpUuid
        let certBundle = Configuration.getConfiguration().CERTBUNDLE
        let backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Smart-ID")
        let certparams = SIDCertificateRequestParameters(relyingPartyName: kRelyingPartyName, relyingPartyUUID: uuid)
        let errorHandler: (SigningError, String) -> Void = { error, log in
            UIApplication.shared.endBackgroundTask(backgroundTask)
            printLog("\(log): \(SkSigningLib_LocalizedString(error.signingErrorDescription ?? error.rawValue))")
            ErrorUtil.generateError(signingError: error, details: MessageUtil.errorMessageWithDetails(details: log))
        }
        
        if isUsingTestMode() {
            printLog("RIA.SmartID - parameters:\n" +
                "\tBase URL: \(baseUrl)\n" +
                "\tUUID: \(uuid)\n"
            )
        }
        
        getCertificate(baseUrl: baseUrl, country: country, nationalIdentityNumber: nationalIdentityNumber, requestParameters: certparams, containerPath: containerPath, trustedCertificates: certBundle, errorHandler: errorHandler) { documentNumber, cert, hash in
            var signparams: SIDSignatureRequestParameters = SIDSignatureRequestParameters()
            if baseUrl.contains("v1") {
                signparams = SIDSignatureRequestParametersV1(relyingPartyName: kRelyingPartyName, relyingPartyUUID: uuid, hash: hash, hashType: hashType, displayText: L(.simToolkitSignDocumentTitle).asUnicode, vcChoice: true)
            } else {
                signparams = SIDSignatureRequestParametersV2(relyingPartyName: kRelyingPartyName, relyingPartyUUID: uuid, hash: hash, hashType: hashType, allowedInteractionsOrder: SIDSignatureRequestAllowedInteractionsOrder(type: "confirmationMessageAndVerificationCodeChoice", displayText: "\(L(.simToolkitSignDocumentTitle).asUnicode) \(FileUtil.getSignDocumentFileName(containerPath: containerPath).asUnicode)"))
            }
            self.getSignature(baseUrl: baseUrl, documentNumber: documentNumber, requestParameters: signparams as? SIDSignatureRequestParametersV1 ?? SIDSignatureRequestParametersV1(), allowedInteractionsOrder: signparams as? SIDSignatureRequestParametersV2 ?? SIDSignatureRequestParametersV2(), trustedCertificates: certBundle, errorHandler: errorHandler) { signatureValue in
                if !RequestCancel.shared.isRequestCancelled() {
                    self.validateSignature(cert: cert, signatureValue: signatureValue)
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                } else {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                    return CancelUtil.handleCancelledRequest(errorMessageDetails: "User cancelled Smart-ID signing")
                }
            }
        }
    }

    private func getCertificate(baseUrl: String, country: String, nationalIdentityNumber: String, requestParameters: SIDCertificateRequestParameters, containerPath: String, trustedCertificates: [String]?, errorHandler: @escaping (SigningError, String) -> Void, completionHandler: @escaping (String, String, String) -> Void) {
        printLog("Getting certificate...")

        if RequestCancel.shared.isRequestCancelled() {
            return CancelUtil.handleCancelledRequest(errorMessageDetails: "User cancelled Smart-ID signing")
        }

        self.selectAccount()
        SIDRequest.shared.getCertificate(baseUrl: baseUrl, country: country, nationalIdentityNumber: nationalIdentityNumber, requestParameters: requestParameters, trustedCertificates: trustedCertificates) { result in
            switch result {
            case .success(let response):
                printLog("Received Certificate (session ID): \(response.sessionID)")
                self.getSessionStatus(baseUrl: baseUrl, sessionId: response.sessionID, trustedCertificates: trustedCertificates) { result in
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

    private func getSignature(baseUrl: String, documentNumber: String, requestParameters: SIDSignatureRequestParametersV1, allowedInteractionsOrder: SIDSignatureRequestParametersV2, trustedCertificates: [String]?, errorHandler: @escaping (SigningError, String) -> Void, completionHandler: @escaping (String) -> Void) {
        printLog("Getting signature...")

        if RequestCancel.shared.isRequestCancelled() {
            return CancelUtil.handleCancelledRequest(errorMessageDetails: "User cancelled Smart-ID signing")
        }

        SIDRequest.shared.getSignature(baseUrl: baseUrl, documentNumber: documentNumber, requestParameters: requestParameters, allowedInteractionsOrder: allowedInteractionsOrder, trustedCertificates: trustedCertificates) { result in
            switch result {
            case .success(let response):
                printLog("Received Signature (session ID): \(response.sessionID)")
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

    private func getSessionStatus(baseUrl: String, sessionId: String, trustedCertificates: [String]?, completionHandler: @escaping (Result<SIDSessionStatusResponse, SigningError>) -> Void) {
        printLog("RIA.SmartID - Requesting session status...")

        if RequestCancel.shared.isRequestCancelled() {
            return CancelUtil.handleCancelledRequest(errorMessageDetails: "User cancelled Smart-ID signing")
        }

        SIDRequest.shared.getSessionStatus(baseUrl: baseUrl, sessionId: sessionId, timeoutMs: kDefaultTimeoutMs, trustedCertificates: trustedCertificates) { result in
            switch result {
            case .success(let sessionStatus):
                printLog("RIA.SmartID - Session status \(sessionStatus.state.rawValue)")
                switch sessionStatus.state {
                case .RUNNING:
                    self.getSessionStatus(baseUrl: baseUrl, sessionId: sessionId, trustedCertificates: trustedCertificates, completionHandler: completionHandler);
                case .COMPLETE:
                    guard let sessionStatusResult = sessionStatus.result else {
                        return completionHandler(.failure(.generalError))
                    }
                    printLog("RIA.SmartID - EndResult: \(sessionStatusResult.endResult.rawValue)")
                    if sessionStatusResult.endResult != .OK {
                        return completionHandler(.failure({
                            switch sessionStatusResult.endResult {
                            case .TIMEOUT: return .accountNotFoundOrTimeout
                            case .USER_REFUSED, .USER_REFUSED_DISPLAYTEXTANDPIN, .USER_REFUSED_VC_CHOICE, .USER_REFUSED_CONFIRMATIONMESSAGE, .USER_REFUSED_CONFIRMATIONMESSAGE_WITH_VC_CHOICE, .USER_REFUSED_CERT_CHOICE: return .userCancelled
                            case .WRONG_VC: return .wrongVC
                            case .DOCUMENT_UNUSABLE: return .documentUnusable
                            case .REQUIRED_INTERACTION_NOT_SUPPORTED_BY_APP: return .interactionNotSupported
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
        printLog("\nRIA.SmartID - Validating signature...\n")
        MoppLibManager.isSignatureValid(cert, signatureValue: signatureValue, success: { (_) in
            printLog("\nRIA.SmartID - Successfully validated signature!\n")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .signatureAddedToContainerNotificationName,
                    object: nil,
                    userInfo: nil)
            }
        }, failure: { (error: Error?) in
            printLog("\nRIA.SmartID - Error validating signature. Error: \(error?.localizedDescription ?? "Unable to display error")\n")
            guard let error = error, let err = error as NSError? else {
                ErrorUtil.generateError(signingError: .generalSignatureAddingError, details: MessageUtil.errorMessageWithDetails(details: "Unknown error"))
                return
            }
            
            if err.code == 5 || err.code == 6 {
                printLog("\nRIA.SmartID - Certificate revoked. \(err.domain)")
                ErrorUtil.generateError(signingError: .certificateRevoked, details: MessageUtil.generateDetailedErrorMessage(error: error as NSError) ?? err.domain)
                return
            } else if err.code == 7 {
                printLog("\nRIA.SmartID - Invalid OCSP time slot. \(err.domain)")
                ErrorUtil.generateError(signingError: .ocspInvalidTimeSlot, details: MessageUtil.generateDetailedErrorMessage(error: error as NSError) ?? err.domain)
                return
            } else if err.code == 18 {
                printLog("\nRIA.SmartID - Too many requests. \(err.domain)")
                ErrorUtil.generateError(signingError: .tooManyRequests, details:
                    MessageUtil.generateDetailedErrorMessage(error: error as NSError) ?? err.domain)
                return
            }
            
            printLog("\nRIA.SmartID - General signature adding error. \(err.domain)")
            return ErrorUtil.generateError(signingError: .empty, details:
                    MessageUtil.generateDetailedErrorMessage(error: error as NSError) ?? err.domain)
        })
    }

    private func setupControlCode(certificateValue: String, containerPath: String) -> String? {
        guard let hash = MoppLibManager.prepareSignature(certificateValue, containerPath: containerPath) else {
            return nil
        }
        
        guard let hashData = Data(base64Encoded: hash) else { return nil }
        
        let digest = sha256(data: hashData)
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
    
    private func sha256(data: Data) -> Data {
        let hashed = SHA256.hash(data: data)
        return Data(hashed)
    }
}

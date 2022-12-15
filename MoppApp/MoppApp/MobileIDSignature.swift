//
//  MobileIDSignature.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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

class MobileIDSignature {
    
    static let shared: MobileIDSignature = MobileIDSignature()
    
    // MARK: Creating Mobile ID signature
    func createMobileIDSignature(phoneNumber: String, nationalIdentityNumber: String, containerPath: String, hashType: String, language: String) -> Void {
        
        if isUsingTestMode() {
            printLog("RIA.MobileID parameters:\n" +
                "\tPhone number: \(phoneNumber)\n" +
                "\tNational Identity number: \(nationalIdentityNumber)\n" +
                "\tHash type: \(hashType)\n" +
                "\tLanguage: \(language)\n"
            )
        }

        let baseUrl = DefaultsHelper.rpUuid.isEmpty ? Configuration.getConfiguration().MIDPROXYURL : Configuration.getConfiguration().MIDSKURL
        let uuid = DefaultsHelper.rpUuid.isEmpty ? kRelyingPartyUUID : DefaultsHelper.rpUuid
        let certBundle = Configuration.getConfiguration().CERTBUNDLE

        // MARK: Request certificate
        getCertificate(baseUrl: baseUrl, uuid: uuid, phoneNumber: phoneNumber, nationalIdentityNumber: nationalIdentityNumber, containerPath: containerPath, trustedCertificates: certBundle, completionHandler: { (hash, cert) in
            // MARK: Request session
            self.getSession(baseUrl: baseUrl, uuid: uuid, phoneNumber: phoneNumber, nationalIdentityNumber: nationalIdentityNumber, hash: hash, hashType: hashType, language: language, trustedCertificates: Configuration.getConfiguration().CERTBUNDLE,  completionHandler: { (sessionId) in
                // MARK: Request session status
                self.getSessionStatus(baseUrl: baseUrl, sessionId: sessionId, cert: cert, trustedCertificates: certBundle, completionHandler: { (signatureValue) in
                    // MARK: Validate signature
                    DispatchQueue.main.async {
                        return self.validateSignature(cert: cert, signatureValue: signatureValue)
                    }
                })
            })
        })
    }

    private func getCertificate(baseUrl: String, uuid: String, phoneNumber: String, nationalIdentityNumber: String, containerPath: String, trustedCertificates: [String]?, completionHandler: @escaping (String, String) -> Void) {
        // MARK: Get certificate
        if isUsingTestMode() {
            printLog("RIA.MobileID - Getting certificate...:\n" +
                "\tBase URL: \(baseUrl)\n" +
                "\tUUID: \(uuid)\n" +
                "\tPhone number: \(phoneNumber)\n" +
                "\tNational Identity number: \(nationalIdentityNumber)\n"
            )
        }
        SessionCertificate.shared.getCertificate(baseUrl: baseUrl, uuid: uuid, phoneNumber: phoneNumber, nationalIdentityNumber: nationalIdentityNumber, trustedCertificates: trustedCertificates) { (sessionCertificate: Result<CertificateResponse, SigningError>) in
            
            let certificateResponse: CertificateResponse
            
            do {
                certificateResponse = try sessionCertificate.getResult()
                
                printLog("\nRIA.MobileID - Received certificate (result): \((certificateResponse.result?.rawValue ?? "Unable to log certificate response result"))\n")
            } catch let certificateError {
                
                let error: Error = certificateError as? SigningError ?? certificateError
                
                printLog("\nRIA.MobileID - Certificate error: \(SkSigningLib_LocalizedString(SigningError(rawValue: "\(certificateError)")?.signingErrorDescription ?? "\(certificateError)"))\n")
                
                guard let mobileCertificateError = certificateError as? SigningError else {
                    return ErrorUtil.generateError(signingError: certificateError as? SigningError ?? SigningError(rawValue: "\(certificateError)") ?? .generalError, details: MessageUtil.errorMessageWithDetails(details: "Unknown error"))
                }
                
                if self.isCountryCodeError(phoneNumber: phoneNumber, errorDesc: "\(mobileCertificateError)") {
                    printLog("\nRIA.MobileID - Error checking country code\n")
                    return ErrorUtil.generateError(signingError: .parameterNameNull, details: MessageUtil.errorMessageWithDetails(details: "Error checking country code"))
                }
                
                if let errorObj = error as? SigningError {
                    return ErrorUtil.generateError(signingError: errorObj, details: MessageUtil.errorMessageWithDetails(details: "Invalid access rights"))
                }
                return ErrorUtil.errorResult(error: error)
            }
            
            guard let cert = certificateResponse.cert else {
                return ErrorUtil.generateError(signingError: .generalError, details: MessageUtil.errorMessageWithDetails(details: "Certificate missing"))
            }
            
            // MARK: Get hash
            guard let hash: String = self.getHash(cert: cert, containerPath: containerPath) else {
                printLog("\nRIA.MobileID - Error getting hash. Is 'cert' empty: \(cert.isEmpty). ContainerPath: \(containerPath)\n")
                return ErrorUtil.generateError(signingError: .generalError, details: MessageUtil.errorMessageWithDetails(details: "Unable to get hash"))
            }
            
            printLog("\nRIA.MobileID - Hash: \(hash)\n")
            
            // MARK: Get control / verification code
            printLog("\nRIA.MobileID - Getting control code\n")
            self.setupControlCode()

            completionHandler(hash, cert)
        }
    }

    private func getSession(baseUrl: String, uuid: String, phoneNumber: String, nationalIdentityNumber: String, hash: String, hashType: String, language: String, trustedCertificates: [String]?, completionHandler: @escaping (String) -> Void) {
        // MARK: Get session
        if isUsingTestMode() {
            printLog("RIA.MobileID - Getting session...:\n" +
                "\tBase URL: \(baseUrl)\n" +
                "\tUUID: \(uuid)\n" +
                "\tPhone number: \(phoneNumber)\n" +
                "\tNational Identity number: \(nationalIdentityNumber)\n" +
                "\tHash type: \(hashType)\n" +
                "\tLanguage: \(language)\n"
            )
        }
        Session.shared.getSession(baseUrl: baseUrl, uuid: uuid, phoneNumber: phoneNumber, nationalIdentityNumber: nationalIdentityNumber, hash: hash, hashType: hashType, language: language, trustedCertificates: trustedCertificates) { (sessionResult: Result<SessionResponse, SigningError>) in

            let sessionResponse: SessionResponse

            do {
                sessionResponse = try sessionResult.getResult()

                printLog("\nRIA.MobileID - Received session (session ID): \(sessionResponse.sessionID ?? "Unable to log sessionID")\n")
                
                guard let sessionId = sessionResponse.sessionID else {
                    printLog("\nRIA.MobileID - Unable to get sessionID\n")

                    return ErrorUtil.generateError(signingError: .generalError, details: MessageUtil.errorMessageWithDetails(details: "Unable to get sessionID"))
                }

                completionHandler(sessionId)
            } catch let sessionError {
                let error: Error = sessionError as? SigningError ?? sessionError
                if let errorObj = error as? SigningError {
                    return ErrorUtil.generateError(signingError: errorObj)
                }
                return ErrorUtil.errorResult(error: error)
            }
        }
    }

    private func getSessionStatus(baseUrl: String, sessionId: String, cert: String, trustedCertificates: [String]?, completionHandler: @escaping (String) -> Void) {
        // MARK: Get session status
        if isUsingTestMode() {
            printLog("RIA.MobileID - Getting session status...:\n" +
                "\tBase URL: \(baseUrl)\n" +
                "\tSession ID: \(sessionId)\n"
            )
        }
        SessionStatus.shared.getSessionStatus(baseUrl: baseUrl, process: .SIGNING, sessionId: sessionId, timeoutMs: kDefaultTimeoutMs, trustedCertificates: trustedCertificates) { (sessionStatusResult: Result<SessionStatusResponse, SigningError>) in

            let sessionStatus: SessionStatusResponse

            do {
                sessionStatus = try sessionStatusResult.getResult()

                printLog("\nRIA.MobileID - Received session status: \(sessionStatus.result?.rawValue ?? "Unable to log session status result")\n")

                if sessionStatus.result != SessionResultCode.OK {
                    guard let sessionStatusResultString = sessionStatus.result else { return }
                    printLog("\nRIA.MobileID - Error completing signing: \(SkSigningLib_LocalizedString(self.handleSessionStatusError(sessionResultCode: sessionStatusResultString).signingErrorDescription ?? "Unable to log session status description"))\n")

                    return ErrorUtil.generateError(signingError: self.handleSessionStatusError(sessionResultCode: sessionStatusResultString))
                }
            } catch let sessionStatusError {
                printLog("\nRIA.MobileID - Unable to get session status: \(sessionStatusError.localizedDescription)\n")
                return ErrorUtil.errorResult(error: sessionStatusError)
            }

            guard let signatureValue = sessionStatus.signature?.value else {
                printLog("\nRIA.MobileID - Unable to get signature value\n")
                return ErrorUtil.generateError(signingError: .generalError, details: MessageUtil.errorMessageWithDetails(details: "Unable to get signature value"))
            }

            if sessionStatus.state == SessionResponseState.COMPLETE {
                completionHandler(signatureValue)
            }
        }
    }
    
    // MARK: Check country code
    private func isCountryCodeError(phoneNumber: String, errorDesc: String) -> Bool {
        return phoneNumber.count <= 8 && (SigningError.notFound == SigningError(rawValue: errorDesc) || SigningError.internalError == SigningError(rawValue: errorDesc))
    }
    
    // MARK: Signature validation
    private func validateSignature(cert: String, signatureValue: String) -> Void {
        if isUsingTestMode() {
            printLog("RIA.MobileID - Validating signature...:\n" +
                "\tCert: \(cert)\n" +
                "\tSignature value: \(signatureValue)\n"
            )
        }
        MoppLibManager.isSignatureValid(cert, signatureValue: signatureValue, success: { (_) in
            printLog("\nRIA.MobileID - Successfully validated signature!\n")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .signatureAddedToContainerNotificationName,
                    object: nil,
                    userInfo: nil)
            }
        }, failure: { (error: Error?) in
            printLog("\nRIA.MobileID - Error validating signature. Error: \(error?.localizedDescription ?? "Unable to display error")\n")
            guard let error = error, let err = error as NSError? else {
                ErrorUtil.generateError(signingError: .generalSignatureAddingError, details: MessageUtil.errorMessageWithDetails(details: "Unknown error"))
                return
            }
            
            if err.code == 7 {
                printLog("\nRIA.MobileID - Invalid OCSP time slot. \(err.domain)")
                ErrorUtil.generateError(signingError: .ocspInvalidTimeSlot, details: MessageUtil.generateDetailedErrorMessage(error: err) ?? "")
                return
            } else if err.code == 18 {
                printLog("\nRIA.MobileID - Too many requests. \(err.domain)")
                ErrorUtil.generateError(signingError: .tooManyRequests, details:
                    MessageUtil.generateDetailedErrorMessage(error: err) ?? "")
                return
            }
            
            printLog("\nRIA.MobileID - General signature adding error. \(err.domain)")
            ErrorUtil.generateError(signingError: .empty, details:
                    MessageUtil.generateDetailedErrorMessage(error: err) ?? "")
            return
        })
    }
    
    // MARK: Control / verification code setup
    private func setupControlCode() {
        guard let verificationCode = self.getVerificationCode() else {
            printLog("\nRIA.MobileID - Failed to get verification code\n")
            return ErrorUtil.generateError(signingError: .generalError, details: MessageUtil.errorMessageWithDetails(details: "Failed to get verification code"))
        }
        
        DispatchQueue.main.async {
            let response: MoppLibMobileCreateSignatureResponse = MoppLibMobileCreateSignatureResponse()
            response.challengeId = verificationCode
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .createSignatureNotificationName,
                    object: nil,
                    userInfo: [kCreateSignatureResponseKey: response]
                )
            }
        }
    }
    
    // MARK: Get hash
    private func getHash(cert: String, containerPath: String) -> String? {
        guard let hash: String = MoppLibManager.prepareSignature(cert, containerPath: containerPath) else {
            printLog("RIA.MobileID - Failed to get hash")
            if isUsingTestMode() {
                printLog("RIA.MobileID - Failed to get hash:\n" +
                    "\tCert: \(cert)\n" +
                    "\tContainer path: \(containerPath)\n"
                )
            }
            ErrorUtil.generateError(signingError: .generalError, details: MessageUtil.errorMessageWithDetails(details: "Failed to get hash"))
            return nil
        }
        
        return hash
    }
    
    // MARK: Get verification code
    private func getVerificationCode() -> String? {
        guard let dataToSign = MoppLibManager.getDataToSign() as? Array<Int>, let verificationCode: String = ControlCode.shared.getVerificationCode(hash: dataToSign) else {
            ErrorUtil.generateError(signingError: .generalError, details: MessageUtil.errorMessageWithDetails(details: "Failed to get verification code"))
            return nil
        }
        return verificationCode
    }
    
    // MARK: Handle session status error
    private func handleSessionStatusError(sessionResultCode: SessionResultCode) -> SigningError {
        switch sessionResultCode {
        case .TIMEOUT:
            return .timeout
        case .NOT_MID_CLIENT:
            return .notMidClient
        case .USER_CANCELLED:
            return .userCancelled
        case .SIGNATURE_HASH_MISMATCH:
            return .signatureHashMismatch
        case .PHONE_ABSENT:
            return .phoneAbsent
        case .DELIVERY_ERROR:
            return .deliveryError
        case .SIM_ERROR:
            return .simError
        default:
            return .generalError
        }
    }
}

extension Result {
    // MARK: Get Result<> result
    func getResult() throws -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}

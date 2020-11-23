//
//  MobileIDSignature.swift
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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
            NSLog("\nUsing phone number: \(phoneNumber.prefix(7))xxxx\n")
            NSLog("\nUsing national identity number: \(nationalIdentityNumber.prefix(6))xxxxx\n")
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
        NSLog("\nGetting certificate...\n")
        SessionCertificate.shared.getCertificate(baseUrl: baseUrl, uuid: uuid, phoneNumber: phoneNumber, nationalIdentityNumber: nationalIdentityNumber, trustedCertificates: trustedCertificates) { (sessionCertificate: Result<CertificateResponse, MobileIDError>) in
            
            let certificateResponse: CertificateResponse
            
            do {
                certificateResponse = try sessionCertificate.getResult()
                
                NSLog("\nReceived certificate (result): \((certificateResponse.result?.rawValue ?? "Unable to log certificate response result"))\n")
            } catch let certificateError {
                
                let error: Error = certificateError as? MobileIDError ?? certificateError
                
                NSLog("\nCertificate error: \((MobileIDError(rawValue: "\(certificateError)")?.mobileIDErrorDescription ?? "\(certificateError)"))\n")
                
                guard let mobileCertificateError = certificateError as? MobileIDError else {
                    return self.generateError(mobileIDError: certificateError as? MobileIDError ?? MobileIDError(rawValue: "\(certificateError)") ?? .generalError)
                }
                
                if self.isCountryCodeError(phoneNumber: phoneNumber, errorDesc: "\(mobileCertificateError)") {
                    NSLog("\nError checking country code\n")
                    return self.generateError(mobileIDError: .parameterNameNull)
                }
                
                if let errorObj = error as? MobileIDError {
                    return self.generateError(mobileIDError: errorObj)
                }
                return self.errorResult(error: error)
            }
            
            guard let cert = certificateResponse.cert else {
                return self.generateError(mobileIDError: .generalError)
            }
            
            // MARK: Get hash
            guard let hash: String = self.getHash(cert: cert, containerPath: containerPath) else {
                NSLog("\nError getting hash. Is 'cert' empty: \(cert.isEmpty). ContainerPath: \(containerPath)\n")
                return self.generateError(mobileIDError: .generalError)
            }
            
            NSLog("\nHash: \(hash)\n")
            
            // MARK: Get control / verification code
            NSLog("\nGetting control code\n")
            self.setupControlCode()

            completionHandler(hash, cert)
        }
    }

    private func getSession(baseUrl: String, uuid: String, phoneNumber: String, nationalIdentityNumber: String, hash: String, hashType: String, language: String, trustedCertificates: [String]?, completionHandler: @escaping (String) -> Void) {
        // MARK: Get session
        NSLog("\nGetting session...\n")
        Session.shared.getSession(baseUrl: baseUrl, uuid: uuid, phoneNumber: phoneNumber, nationalIdentityNumber: nationalIdentityNumber, hash: hash, hashType: hashType, language: language, trustedCertificates: trustedCertificates) { (sessionResult: Result<SessionResponse, MobileIDError>) in

            let sessionResponse: SessionResponse

            do {
                sessionResponse = try sessionResult.getResult()

                NSLog("\nReceived session (session ID redacted): \(sessionResponse.sessionID?.prefix(13) ?? "Unable to log sessionID")\n")
            } catch let sessionError {
                let error: Error = sessionError as? MobileIDError ?? sessionError
                if let errorObj = error as? MobileIDError {
                    return self.generateError(mobileIDError: errorObj)
                }
                return self.errorResult(error: error)
            }

            guard let sessionId = sessionResponse.sessionID else {
                NSLog("\nUnable to get sessionID\n")

                return self.generateError(mobileIDError: .generalError)
            }

            completionHandler(sessionId)
        }
    }

    private func getSessionStatus(baseUrl: String, sessionId: String, cert: String, trustedCertificates: [String]?, completionHandler: @escaping (String) -> Void) {
        // MARK: Get session status
        NSLog("\nGetting session status...\n")
        SessionStatus.shared.getSessionStatus(baseUrl: baseUrl, process: .SIGNING, sessionId: sessionId, timeoutMs: 1000, trustedCertificates: trustedCertificates) { (sessionStatusResult: Result<SessionStatusResponse, MobileIDError>) in

            let sessionStatus: SessionStatusResponse

            do {
                sessionStatus = try sessionStatusResult.getResult()

                NSLog("\nReceived session status: \(sessionStatus.result?.rawValue ?? "Unable to log session status result")\n")

                if sessionStatus.result != SessionResultCode.OK {
                    guard let sessionStatusResultString = sessionStatus.result else { return }
                    NSLog("\nError completing signing: \(self.handleSessionStatusError(sessionResultCode: sessionStatusResultString).mobileIDErrorDescription ?? "Unable to log session status description")\n")

                    return self.generateError(mobileIDError: self.handleSessionStatusError(sessionResultCode: sessionStatusResultString))
                }
            } catch let sessionStatusError {
                NSLog("\nUnable to get session status: \(sessionStatusError)\n")
                return self.errorResult(error: sessionStatusError)
            }

            guard let signatureValue = sessionStatus.signature?.value else {
                NSLog("\nUnable to get signature value\n")
                return self.generateError(mobileIDError: .generalError)
            }

            completionHandler(signatureValue)
        }
    }
    
    // MARK: Check country code
    private func isCountryCodeError(phoneNumber: String, errorDesc: String) -> Bool {
        return phoneNumber.count <= 8 && MobileIDError.notFound == MobileIDError(rawValue: errorDesc) ? true : false
    }
    
    // MARK: Signature validation
    private func validateSignature(cert: String, signatureValue: String) -> Void {
        NSLog("\nValidating signature...\n")
        if MoppLibManager.isSignatureValid(cert, signatureValue: signatureValue) {
            NSLog("\nSuccessfully validated signature!\n")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .signatureAddedToContainerNotificationName,
                    object: nil,
                    userInfo: nil)
            }
        }
        else {
            NSLog("\nError validating signature\n")
            generateError(mobileIDError: .generalError)
        }
    }
    
    // MARK: Control / verification code setup
    private func setupControlCode() {
        guard let verificationCode = self.getVerificationCode() else {
            NSLog("\nFailed to get verification code\n")
            return self.generateError(mobileIDError: .generalError)
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
    
    // MARK: Error generating
    private func generateError(mobileIDError: MobileIDError) -> Void {
        let error = NSError(domain: "SkSigningLib", code: 10, userInfo: [NSLocalizedDescriptionKey: mobileIDError])
        return self.errorResult(error: error)
    }
    
    // MARK: Get hash
    private func getHash(cert: String, containerPath: String) -> String? {
        guard let hash: String = MoppLibManager.prepareSignature(cert, containerPath: containerPath) else {
            NSLog("Failed to get hash")
            self.generateError(mobileIDError: .generalError)
            return nil
        }
        
        return hash
    }
    
    // MARK: Get verification code
    private func getVerificationCode() -> String? {
        guard let verificationCode: String = ControlCode.shared.getVerificationCode(hash: MoppLibManager.getDataToSign() as! Array<Int>) else {
            self.generateError(mobileIDError: .generalError)
            return nil
        }
        return verificationCode
    }
    
    // MARK: Submit error result
    private func errorResult(error: Error) -> Void {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .errorNotificationName, object: nil, userInfo: [kErrorKey: error])
        }
    }
    
    // MARK: Handle session status error
    private func handleSessionStatusError(sessionResultCode: SessionResultCode) -> MobileIDError {
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
    
    // MARK: Test mode check
    private func isUsingTestMode() -> Bool {
        #if USE_TEST_DDS
            let testMode: Bool = true
        #else
            let testMode: Bool = false
        #endif
        
        return testMode
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

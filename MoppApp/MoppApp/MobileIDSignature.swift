//
//  MobileIDSignature.swift
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

import SkSigningLib

class MobileIDSignature {
    
    static let shared: MobileIDSignature = MobileIDSignature()
    
    // MARK: Creating Mobile ID signature
    func createMobileIDSignature(phoneNumber: String, nationalIdentityNumber: String, containerPath: String, hashType: String, language: String, roleData: MoppLibRoleAddressData?) -> Void {

        printLog("RIA.MobileID parameters:\n" +
                 "\tPhone number: \(isUsingTestMode() ? phoneNumber : "xxxx")\n" +
                 "\tNational Identity number: \(isUsingTestMode() ? nationalIdentityNumber : "xxxx")\n" +
            "\tHash type: \(hashType)\n" +
            "\tLanguage: \(language)\n"
        )

        let baseUrl = DefaultsHelper.rpUuid.isEmpty ? Configuration.getConfiguration().MIDPROXYURL : Configuration.getConfiguration().MIDSKURL
        let uuid = DefaultsHelper.rpUuid.isEmpty ? kRelyingPartyUUID : DefaultsHelper.rpUuid
        let certBundle = Configuration.getConfiguration().CERTBUNDLE

        // MARK: Request certificate
        getCertificate(baseUrl: baseUrl, uuid: uuid, phoneNumber: phoneNumber, nationalIdentityNumber: nationalIdentityNumber, containerPath: containerPath, roleData: roleData, trustedCertificates: certBundle, completionHandler: { hash in
            // MARK: Request session
            self.getSession(baseUrl: baseUrl, uuid: uuid, phoneNumber: phoneNumber, nationalIdentityNumber: nationalIdentityNumber, hash: hash, hashType: hashType, language: language, trustedCertificates: Configuration.getConfiguration().CERTBUNDLE,  completionHandler: { (sessionId) in
                // MARK: Request session status
                self.getSessionStatus(baseUrl: baseUrl, sessionId: sessionId, trustedCertificates: certBundle, completionHandler: { (signatureValue) in
                    if !RequestCancel.shared.isRequestCancelled() {
                        // MARK: Validate signature
                        DispatchQueue.main.async {
                            return self.validateSignature(signatureValue: signatureValue)
                        }
                    } else {
                        return CancelUtil.handleCancelledRequest(errorMessageDetails: "User cancelled Mobile-ID signing")
                    }
                })
            })
        })
    }

    private func getCertificate(baseUrl: String, uuid: String, phoneNumber: String, nationalIdentityNumber: String, containerPath: String, roleData: MoppLibRoleAddressData?, trustedCertificates: [Data], completionHandler: @escaping (Data) -> Void) {

        if RequestCancel.shared.isRequestCancelled() {
            return CancelUtil.handleCancelledRequest(errorMessageDetails: "User cancelled Mobile-ID signing")
        }

        // MARK: Get certificate
        printLog("RIA.MobileID - Getting certificate...:\n" +
            "\tBase URL: \(baseUrl)\n" +
            "\tUUID: \(uuid)\n" +
            "\tPhone number: \(isUsingTestMode() ? phoneNumber : "xxxx")\n" +
            "\tNational Identity number: \(isUsingTestMode() ? nationalIdentityNumber: "xxxx")\n"
        )

        SessionCertificate.shared.getCertificate(baseUrl: baseUrl, uuid: uuid, phoneNumber: phoneNumber, nationalIdentityNumber: nationalIdentityNumber, trustedCertificates: trustedCertificates) { (sessionCertificate: Result<CertificateResponse, SigningError>) in
            
            let certificateResponse: CertificateResponse
            
            do {
                certificateResponse = try sessionCertificate.getResult()
                
                printLog("\nRIA.MobileID - Received certificate (result): \((certificateResponse.result?.rawValue ?? "Unable to log certificate response result"))\n")
            } catch let certificateError {
                
                let error: Error = certificateError as? SigningError ?? certificateError
                
                printLog("\nRIA.MobileID - Certificate error: \(SkSigningLib_LocalizedString(SigningError(rawValue: "\(certificateError)")?.errorDescription ?? "\(certificateError)"))\n")
                
                guard let mobileCertificateError = certificateError as? SigningError else {
                    return ErrorUtil.generateError(signingError: (certificateError as? SigningError ?? SigningError(rawValue: "\(certificateError)")) ?? SigningError.generalError , details: MessageUtil.errorMessageWithDetails(details: "Unknown error"))
                }
                
                if self.isCountryCodeError(phoneNumber: phoneNumber, errorDesc: "\(mobileCertificateError)") {
                    printLog("\nRIA.MobileID - Error checking country code\n")
                    return ErrorUtil.generateError(signingError: .parameterNameNull, details: MessageUtil.errorMessageWithDetails(details: "Error checking country code"))
                }
                
                if let errorObj = error as? SigningError {
                    if errorObj == .invalidProxySettings {
                        return ErrorUtil.generateError(signingError: errorObj)
                    }
                    return ErrorUtil.generateError(signingError: errorObj, details: MessageUtil.errorMessageWithDetails(details: "Invalid access rights"))
                }
                return ErrorUtil.errorResult(error: error)
            }
            
            guard let cert = certificateResponse.cert else {
                return ErrorUtil.generateError(signingError: .generalError, details: MessageUtil.errorMessageWithDetails(details: "Certificate missing"))
            }
            
            // MARK: Get hash
            guard let hash = self.getHash(cert: cert, containerPath: containerPath, roleData: roleData) else { return }
            
            printLog("\nRIA.MobileID - Hash: \(hash)\n")
            
            // MARK: Get control / verification code
            printLog("\nRIA.MobileID - Getting control code\n")
            self.setupControlCode(dataToSign: hash)

            completionHandler(hash)
        }
    }

    private func getSession(baseUrl: String, uuid: String, phoneNumber: String, nationalIdentityNumber: String, hash: Data, hashType: String, language: String, trustedCertificates: [Data], completionHandler: @escaping (String) -> Void) {

        if RequestCancel.shared.isRequestCancelled() {
            return CancelUtil.handleCancelledRequest(errorMessageDetails: "User cancelled Mobile-ID signing")
        }

        // MARK: Get session
        printLog("RIA.MobileID - Getting session...:\n" +
            "\tBase URL: \(baseUrl)\n" +
            "\tUUID: \(uuid)\n" +
             "\tPhone number: \(isUsingTestMode() ? phoneNumber : "xxxx")\n" +
             "\tNational Identity number: \(isUsingTestMode() ? nationalIdentityNumber : "xxxx")\n" +
            "\tHash type: \(hashType)\n" +
            "\tLanguage: \(language)\n"
        )

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
                    if errorObj == .invalidProxySettings {
                        return ErrorUtil.generateError(signingError: errorObj)
                    }
                    return ErrorUtil.generateError(signingError: errorObj)
                }
                return ErrorUtil.errorResult(error: error)
            }
        }
    }

    private func getSessionStatus(baseUrl: String, sessionId: String, trustedCertificates: [Data], completionHandler: @escaping (Data) -> Void) {

        if RequestCancel.shared.isRequestCancelled() {
            return CancelUtil.handleCancelledRequest(errorMessageDetails: "User cancelled Mobile-ID signing")
        }

        // MARK: Get session status
        printLog("RIA.MobileID - Getting session status...:\n" +
            "\tBase URL: \(baseUrl)\n" +
            "\tSession ID: \(sessionId)\n"
        )

        SessionStatus.shared.getSessionStatus(baseUrl: baseUrl, process: .SIGNING, sessionId: sessionId, timeoutMs: kDefaultTimeoutMs, trustedCertificates: trustedCertificates) { (sessionStatusResult: Result<SessionStatusResponse, SigningError>) in

            let sessionStatus: SessionStatusResponse

            do {
                sessionStatus = try sessionStatusResult.getResult()

                printLog("\nRIA.MobileID - Received session status: \(sessionStatus.result?.rawValue ?? "Unable to log session status result")\n")

                if sessionStatus.result != SessionResultCode.OK {
                    guard let sessionStatusResultString = sessionStatus.result else { return }
                    printLog("\nRIA.MobileID - Error completing signing: \(SkSigningLib_LocalizedString(self.handleSessionStatusError(sessionResultCode: sessionStatusResultString).errorDescription ?? "Unable to log session status description"))\n")

                    return ErrorUtil.generateError(signingError: self.handleSessionStatusError(sessionResultCode: sessionStatusResultString))
                }
            } catch let sessionStatusError {
                printLog("\nRIA.MobileID - Unable to get session status: \(sessionStatusError.localizedDescription)\n")
                let error: Error = sessionStatusError as? SigningError ?? sessionStatusError
                if let errorObj = error as? SigningError {
                    if errorObj == .invalidProxySettings {
                        return ErrorUtil.generateError(signingError: errorObj)
                    }
                    return ErrorUtil.generateError(signingError: errorObj)
                }
                return ErrorUtil.errorResult(error: error)
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
        let signingError = SigningError(rawValue: errorDesc)

        return phoneNumber.count <= 8 &&
            (signingError == .notFound || signingError == .internalError)
    }
    
    // MARK: Signature validation
    private func validateSignature(signatureValue: Data) -> Void {
        printLog("RIA.MobileID - Validating signature...:\n" +
            "\tSignature value: \(signatureValue)\n"
        )
        do {
            try MoppLibContainerActions.isSignatureValid(signatureValue)
            printLog("\nRIA.MobileID - Successfully validated signature!\n")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .signatureAddedToContainerNotificationName,
                    object: nil,
                    userInfo: nil)
            }
        } catch {
            ErrorUtil.generateError(signingError: error, signingType: SigningType.mobileId)
        }
    }
    
    // MARK: Control / verification code setup
    private func setupControlCode(dataToSign: Data) {
        guard let verificationCode = ControlCode.shared.getVerificationCode(hash: dataToSign) else {
            printLog("\nRIA.MobileID - Failed to get verification code\n")
            return ErrorUtil.generateError(signingError: .generalError, details: MessageUtil.errorMessageWithDetails(details: "Failed to get verification code"))
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .createSignatureNotificationName,
                object: nil,
                userInfo: [kCreateSignatureResponseKey: verificationCode]
            )
        }
    }
    
    // MARK: Get hash
    private func getHash(cert: Data, containerPath: String, roleData: MoppLibRoleAddressData?) -> Data? {
        do {
            return try MoppLibContainerActions.prepareSignature(cert, containerPath: containerPath, roleData: roleData, isNFCSignature: false)
        } catch let error as NSError {
            printLog("RIA.MobileID - Failed to get hash:\n" +
                "\tCert: \(cert)\n" +
                "\tContainer path: \(containerPath)\n"
            )

            ErrorUtil.generateError(signingError: .generalError, details: MessageUtil.errorMessageWithDetails(details: error.localizedDescription + "\nFailed to get hash"))
            return nil
        }
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

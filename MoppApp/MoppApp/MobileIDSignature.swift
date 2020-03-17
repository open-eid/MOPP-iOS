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
    
    func createMobileIDSignature(baseUrl: String, phoneNumber: String, nationalIdentityNumber: String, containerPath: String, hashType: String, language: String) -> Void {
        
        NSLog("\nGetting certificate...\n")
        SessionCertificate.shared.getCertificate(baseUrl: baseUrl, phoneNumber: phoneNumber, nationalIdentityNumber: nationalIdentityNumber) { (sessionCertificate: Result<CertificateResponse, MobileIDError>) in
            
            let certificateResponse: CertificateResponse
            
            do {
                certificateResponse = try sessionCertificate.getResult()
                
                NSLog("\nReceived certificate (result): \((certificateResponse.result?.rawValue ?? "Unable to log certificate response result"))\n")
            } catch let certificateError {
                let error = NSError(domain: "SkSigningLib", code: 1, userInfo: [NSLocalizedDescriptionKey: certificateError as? MobileIDError ?? certificateError])
                
                NSLog("\nCertificate error: \(((error as? MobileIDError)?.mobileIDErrorDescription ?? "\(certificateError)"))\n")
                
                guard let mobileCertificateError = certificateError as? MobileIDError else {
                    return self.errorResult(error: error)
                }
                
                if self.isCountryCodeError(phoneNumber: phoneNumber, errorDesc: "\(mobileCertificateError)") {
                    NSLog("\nError checking country code\n")
                    let parameterError = NSError(domain: "SkSigningLib", code: 4, userInfo: [NSLocalizedDescriptionKey: MobileIDError.parameterNameNull])
                    return self.errorResult(error: parameterError)
                }
                
                return self.errorResult(error: error)
            }
            
            guard let cert = certificateResponse.cert else {
                return
            }
            
            guard let hash: String = self.getHash(cert: cert, containerPath: containerPath) else {
                NSLog("\nError getting hash. Is 'cert' empty: \(cert.isEmpty). ContainerPath: \(containerPath)\n")
                let error = NSError(domain: "SkSigningLib", code: 4, userInfo: [NSLocalizedDescriptionKey: MobileIDError.generalError])
                return self.errorResult(error: error)
            }
            
            NSLog("\nHash: \(hash)\n")
            
            NSLog("\nGetting control code\n")
            self.setupControlCode()
            
            NSLog("\nGetting session...\n")
            Session.shared.getSession(baseUrl: baseUrl, phoneNumber: phoneNumber, nationalIdentityNumber: nationalIdentityNumber, hash: hash, hashType: hashType, language: language) { (sessionResult: Result<SessionResponse, MobileIDError>) in
                
                let sessionResponse: SessionResponse
                
                do {
                    sessionResponse = try sessionResult.getResult()
                    
                    NSLog("\nReceived session (session ID redacted): \(sessionResponse.sessionID?.prefix(13) ?? "Unable to log sessionID")\n")
                } catch let sessionError {
                    let error = NSError(domain: "SkSigningLib", code: 2, userInfo: [NSLocalizedDescriptionKey: sessionError as? MobileIDError ?? sessionError])
                    
                    return self.errorResult(error: error)
                }
                
                guard let sessionId = sessionResponse.sessionID else {
                    NSLog("\nUnable to get sessionID\n")
                    let error = NSError(domain: "SkSigningLib", code: 2, userInfo: [NSLocalizedDescriptionKey: MobileIDError.generalError])
                    
                    return self.errorResult(error: error)
                }
                
                NSLog("\nGetting session status...\n")
                SessionStatus.shared.getSessionStatus(baseUrl: baseUrl, process: .SIGNING, sessionId: sessionId, timeoutMs: 1000) { (sessionStatusResult: Result<SessionStatusResponse, MobileIDError>) in
                    
                    let sessionStatus: SessionStatusResponse
                    
                    do {
                        sessionStatus = try sessionStatusResult.getResult()
                        
                        NSLog("\nReceived session status: \(sessionStatus.result?.rawValue ?? "Unable to log session status result")\n")
                    } catch let sessionStatusError {
                        NSLog("\nUnable to get session status: \(sessionStatusError)\n")
                        return self.errorResult(error: sessionStatusError)
                    }
                    
                    if sessionStatus.result != SessionResultCode.OK {
                        guard let sessionStatusResultString = sessionStatus.result else { return }
                        let error = NSError(domain: "SkSigningLib", code: 3, userInfo: [NSLocalizedDescriptionKey: self.handleSessionStatusError(sessionResultCode: sessionStatusResultString)])
                        NSLog("\nError completing signing: \(self.handleSessionStatusError(sessionResultCode: sessionStatusResultString).mobileIDErrorDescription ?? "Unable to log session status description")\n")
                        return self.errorResult(error: error)
                    }
                    
                    guard let signatureValue = sessionStatus.signature?.value else {
                        let error = NSError(domain: "SkSigningLib", code: 6, userInfo: [NSLocalizedDescriptionKey: MobileIDError.generalError])
                        NSLog("\nUnable to get signature value\n")
                        return self.errorResult(error: error)
                    }
                    
                    DispatchQueue.main.async {
                        NSLog("\nValidating signature...\n")
                        return self.validateSignature(cert: cert, signatureValue: signatureValue)
                    }
                }
            }
        }
    }
    
    private func isCountryCodeError(phoneNumber: String, errorDesc: String) -> Bool {
        return phoneNumber.count <= 8 && MobileIDError.notFound == MobileIDError(rawValue: errorDesc) ? true : false
    }
    
    private func validateSignature(cert: String, signatureValue: String) -> Void {
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
            let error = NSError(domain: "SkSigningLib", code: 5, userInfo: [NSLocalizedDescriptionKey: MobileIDError.generalError])
            errorResult(error: error)
        }
    }
    
    private func setupControlCode() {
        guard let verificationCode = self.getVerificationCode() else {
            NSLog("\nFailed to get verification code\n")
            let error = NSError(domain: "SkSigningLib", code: 3, userInfo: [NSLocalizedDescriptionKey: MobileIDError.generalError])
            return self.errorResult(error: error)
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
    
    
    
    
    private func getHash(cert: String, containerPath: String) -> String? {
        guard let hash: String = MoppLibManager.getContainerHash(cert, containerPath: containerPath) else {
            NSLog("Failed to get hash")
            let error = NSError(domain: "SkSigningLib", code: 7, userInfo: [NSLocalizedDescriptionKey: MobileIDError.generalError])
            errorResult(error: error)
            return nil
        }
        
        return hash
    }
    
    func getVerificationCode() -> String? {
        guard let verificationCode: NSNumber = MoppLibManager.sharedInstance()?.getVerificationCode() as NSNumber? else {
            NSLog("Failed to get verification code")
            let error = NSError(domain: "SkSigningLib", code: 8, userInfo: [NSLocalizedDescriptionKey: MobileIDError.generalError])
            errorResult(error: error)
            return nil
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumIntegerDigits = 4
        numberFormatter.maximumIntegerDigits = 4
        
        guard let verificationCodeString = numberFormatter.string(from: verificationCode) else {
            NSLog("Failed to get string formatted verification code")
            let error = NSError(domain: "SkSigningLib", code: 9, userInfo: [NSLocalizedDescriptionKey: MobileIDError.generalError])
            errorResult(error: error)
            return nil
        }
        
        return verificationCodeString
    }
    
    func errorResult(error: Error) -> Void {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .errorNotificationName, object: nil, userInfo: [kErrorKey: error])
        }
    }
    
    func handleSessionStatusError(sessionResultCode: SessionResultCode) -> MobileIDError {
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
    func getResult() throws -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}

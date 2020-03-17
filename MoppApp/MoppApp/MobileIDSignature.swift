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
        
        SessionCertificate.shared.getCertificate(baseUrl: baseUrl, phoneNumber: phoneNumber, nationalIdentityNumber: nationalIdentityNumber) { (sessionCertificate: Result<CertificateResponse, MobileIDError>) in
            
            let certificateResponse: CertificateResponse
            
            do {
                certificateResponse = try sessionCertificate.getResult()
            } catch let certificateError {
                let error = NSError(domain: "SkSigningLib", code: 1, userInfo:[NSLocalizedDescriptionKey: certificateError as? MobileIDError ?? certificateError])
                
                guard let mobileCertificateError = certificateError as? MobileIDError else {
                    return self.errorResult(error: error)
                }
                
                if self.isCountryCodeError(phoneNumber: phoneNumber, errorDesc: "\(mobileCertificateError)") {
                    let parameterError = NSError(domain: "SkSigningLib", code: 4, userInfo:[NSLocalizedDescriptionKey: MobileIDError.parameterNameNull])
                    return self.errorResult(error: parameterError)
                }
                    
                return self.errorResult(error: error)
            }
            
            guard let cert = certificateResponse.cert else {
                return
            }
            
            guard let hash: String = self.getHash(cert: cert, containerPath: containerPath) else {
                let error = NSError(domain: "SkSigningLib", code: 4, userInfo:[NSLocalizedDescriptionKey: MobileIDError.generalError])
                return self.errorResult(error: error)
            }
            
            NSLog("\nHash: \(hash)\n")
            
            self.setupControlCode()
            
            Session.shared.getSession(baseUrl: baseUrl, phoneNumber: phoneNumber, nationalIdentityNumber: nationalIdentityNumber, hash: hash, hashType: hashType, language: language) { (sessionResult: Result<SessionResponse, MobileIDError>) in
                
                let sessionResponse: SessionResponse
                
                do {
                    sessionResponse = try sessionResult.getResult()
                } catch let sessionError {
                    let error = NSError(domain: "SkSigningLib", code: 2, userInfo:[NSLocalizedDescriptionKey:
                    sessionError as? MobileIDError ?? sessionError])
                    
                    return self.errorResult(error: error)
                }
                
                guard let sessionId = sessionResponse.sessionID else {
                    return
                }
                
                SessionStatus.shared.getSessionStatus(baseUrl: baseUrl, process: .SIGNING, sessionId: sessionId, timeoutMs: 1000) { (sessionStatusResult: Result<SessionStatusResponse, MobileIDError>) in
                    
                    let sessionStatus: SessionStatusResponse
                    
                    do {
                        sessionStatus = try sessionStatusResult.getResult()
                    } catch let sessionStatusError {
                        return self.errorResult(error: sessionStatusError)
                    }
                    
                    if sessionStatus.result != SessionResultCode.OK {
                        guard let sessionStatusResultString = sessionStatus.result else { return }
                        let error = NSError(domain: "SkSigningLib", code: 3, userInfo:[NSLocalizedDescriptionKey: self.handleSessionStatusError(sessionResultCode: sessionStatusResultString)])
                        return self.errorResult(error: error)
                    }
                    
                    guard let signatureValue = sessionStatus.signature?.value else {
                        return
                    }
                    
                    DispatchQueue.main.async {
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
        if MoppLibManager.sharedInstance()?.isSignatureValid(cert, signatureValue: signatureValue) ?? false {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .signatureAddedToContainerNotificationName,
                    object: nil,
                    userInfo: nil)
            }
        }
        else {
            errorResult(error: NSError())
        }
    }
    
    private func setupControlCode() {
        guard let verificationCode = self.getVerificationCode() else {
            let error = NSError(domain: "SkSigningLib", code: 3, userInfo:[NSLocalizedDescriptionKey: MobileIDError.generalError])
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
        guard let hash: String = MoppLibManager.sharedInstance()?.getContainerHash(cert, containerPath: containerPath) else {
            errorResult(error: NSError())
            return nil
        }
        
        return hash
    }
    
    func getVerificationCode() -> String? {
        guard let verificationCode: NSNumber = MoppLibManager.sharedInstance()?.getVerificationCode() as NSNumber? else {
            NSLog("Failed to get verification code")
            self.errorResult(error: NSError())
            return nil
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumIntegerDigits = 4
        numberFormatter.maximumIntegerDigits = 4
        
        guard let verificationCodeString = numberFormatter.string(from: verificationCode) else {
            self.errorResult(error: NSError())
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

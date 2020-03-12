//
//  SigningActions.swift
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



protocol SigningActions {
   func startSigningProcess()
   func appendSignatureWarnings()
   func sortSignatures()
   func removeContainerSignature(signatureIndex: Int)
}

extension SigningActions where Self: SigningContainerViewController {
    
    func removeContainerSignature(signatureIndex: Int) {
        guard let signature = container.signatures[signatureIndex] as? MoppLibSignature else {
            return
        }
        confirmDeleteAlert(
            message: L(.signatureRemoveConfirmMessage),
            confirmCallback: { [weak self] (alertAction) in
                
                self?.notifications = []
                self?.updateState(.loading)
                MoppLibContainerActions.sharedInstance().remove(
                    signature,
                    fromContainerWithPath: self?.container.filePath,
                    success: { [weak self] container in
                        self?.updateState((self?.isCreated ?? false) ? .created : .opened)
                        self?.container.signatures.remove(at: signatureIndex)
                        self?.reloadData()
                    },
                    failure: { [weak self] error in
                        self?.updateState((self?.isCreated ?? false) ? .created : .opened)
                        self?.reloadData()
                        self?.errorAlert(message: error?.localizedDescription)
                })
        })
    }
    
    func startSigningProcess() {
        
        if signingContainerViewDelegate.isContainerSignable() {
            let signSelectionVC = UIStoryboard.tokenFlow.instantiateViewController(of: TokenFlowSelectionViewController.self)
            signSelectionVC.modalPresentationStyle = .overFullScreen
            
            signSelectionVC.mobileIdEditViewControllerDelegate = self
            signSelectionVC.idCardSignViewControllerDelegate = self
            signSelectionVC.containerPath = containerPath
            
            LandingViewController.shared.present(signSelectionVC, animated: false, completion: nil)
        } else {
            createNewContainerForNonSignableContainerAndSign()
        }
    }
    
    func appendSignatureWarnings() {
        
        if self.invalidSignaturesCount > 0 {
            var signatureWarningText: String!
            if self.invalidSignaturesCount == 1 {
                signatureWarningText = L(.containerErrorMessageInvalidSignature)
            } else if self.invalidSignaturesCount > 1 {
                signatureWarningText = L(.containerErrorMessageInvalidSignatures, [self.invalidSignaturesCount])
            }
            self.notifications.append((false, signatureWarningText))
        }
        
        if self.unknownSignaturesCount > 0 {
            var signatureWarningText: String!
            if self.unknownSignaturesCount == 1 {
                signatureWarningText = L(.containerErrorMessageUnknownSignature)
            } else if self.unknownSignaturesCount > 1 {
                signatureWarningText = L(.containerErrorMessageUnknownSignatures, [self.unknownSignaturesCount])
            }
            self.notifications.append((false, signatureWarningText))
        }
    }
    
    func sortSignatures() {
        container.signatures.sort { (sig1: Any, sig2: Any) -> Bool in
            let signatureStatusValue1 = (sig1 as! MoppLibSignature).status.rawValue
            let signatureStatusValue2 = (sig2 as! MoppLibSignature).status.rawValue
            if signatureStatusValue1 == signatureStatusValue2 {
                return (sig1 as! MoppLibSignature).timestamp < (sig2 as! MoppLibSignature).timestamp
            }
            return signatureStatusValue1 > signatureStatusValue2
            
        }
    }
}

extension SigningContainerViewController : MobileIDEditViewControllerDelegate {
    func mobileIDEditViewControllerDidDismiss(cancelled: Bool, phoneNumber: String?, idCode: String?) {
        if cancelled { return }
        
        guard let phoneNumber = phoneNumber else { return }
        guard let idCode = idCode else { return }
        
        let mobileIDChallengeview = UIStoryboard.tokenFlow.instantiateViewController(of: MobileIDChallengeViewController.self)
        mobileIDChallengeview.modalPresentationStyle = .overFullScreen
        present(mobileIDChallengeview, animated: false)
        
        // MARK: Get Mobile-ID Certificate
        getMobileIDCertificate(baseUrl: "https://dd-mid.ria.ee/mid-api", phoneNumber: phoneNumber, nationalIdentityNumber: idCode) { (certificateResult: Result<CertificateResponse, CertificateResponseError>) in
            switch certificateResult {
            case .success(let certificateResponse):
                // MARK: Generate Hash
                self.generateHash(cert: certificateResponse.cert ?? "", digestMethod: kDigestMethodSHA256, signingValue: "", containerPath: self.containerViewDelegate.getContainerPath()) { (hash, sId, error) in
//                    MoppLibManager.sharedInstance()?.getVerificationCode(hash);
                    print("\nReceived hash: \(hash)\n")
                    
                    DispatchQueue.main.async {
                        let response: MoppLibMobileCreateSignatureResponse = MoppLibMobileCreateSignatureResponse()
                        response.challengeId = "\(self.generateVerificationCode(hash: MoppLibManager.sharedInstance()?.getDataToSign() ?? Data()))"
                        NotificationCenter.default.post(
                            name: .createSignatureNotificationName,
                            object: nil,
                            userInfo: [kCreateSignatureResponseKey: response]
                        )
                    }
                    
                    
                    // MARK: Get Mobile ID Session
                    self.getMobileIDSession(baseUrl: "https://dd-mid.ria.ee/mid-api", phoneNumber: phoneNumber, nationalIdentityNumber: idCode, hash: hash, hashType: kHashType, language: self.decideLanguageBasedOnPreferredLanguages()) { (sessionResult) in
                        switch sessionResult {
                        case .success(let sessionResponse):
                            // MARK: Get Mobile ID Session Status
                            self.getMobileIDSessionStatus(baseUrl: "https://dd-mid.ria.ee/mid-api", process: .SIGNING, sessionId: sessionResponse.sessionID ?? "", timeoutMs: 1000) { (sessionStatusResult) in
                                switch sessionStatusResult {
                                case .success(let sessionStatusResponse):
                                    // MARK: Validate Mobile ID Signature
//                                    MoppLibManager.sharedInstance()?.validateSignature(sessionStatusResponse.signature?.value, signatureId: sId, containerPath: self.containerViewDelegate.getContainerPath(), cert: certificateResponse.cert, success: {
////                                        self.containerViewDelegate.openContainer(afterSignatureCreated: true)
//                                    }, andFailure: { error in
//                                        print(error)
//                                    })
                                    
                                    self.generateHash(cert: certificateResponse.cert!, digestMethod: kDigestMethodSHA256, signingValue: sessionStatusResponse.signature!.value, containerPath: self.containerViewDelegate.getContainerPath()) { (first, second, error) in
                                    }
                                case .failure(let sessionStatusError):
                                    print(sessionStatusError)
                                }
                            }
                        case .failure(let sessionError):
                            print(sessionError)
                        }
                    }
                }
            case .failure(let certificateError):
                print(certificateError)
            }
        }
        
//        Session.shared.createMobileSignature(
//            withContainer: containerViewDelegate.getContainerPath(),
//            idCode: idCode,
//            language: decideLanguageBasedOnPreferredLanguages(),
//            phoneNumber: phoneNumber)
    }
    
    func getMobileIDCertificate(baseUrl: String, phoneNumber: String, nationalIdentityNumber: String, completionHandler: @escaping (Result<CertificateResponse, CertificateResponseError>) -> Void) -> Void {
        do {
            _ = try RequestSignature.shared.getCertificate(baseUrl: baseUrl, requestParameters: CertificateRequestParameters(relyingPartyUUID: kRelyingPartyUUID, relyingPartyName: kRelyingPartyName, phoneNumber: "+\(phoneNumber)", nationalIdentityNumber: nationalIdentityNumber)) { (result) in
                
                switch result {
                case .success(let response):
//                    print(response)
                    completionHandler(.success(response))
                case .failure(let error):
                    print(error)
                    print(error.localizedDescription)
                    print(error.errorDescription)
                    completionHandler(.failure(error))
                    
                    DispatchQueue.main.async {
                          self.dismiss(animated: false) {
                              let alert = UIAlertController(title: kErrorKey, message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                              alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                              self.present(alert, animated: true, completion: nil)
                          }
                        
                    }
                }
            }
        } catch let error {
            print(error)
        }
    }
    
    func getMobileIDSession(baseUrl: String, phoneNumber: String, nationalIdentityNumber: String, hash: String, hashType: String, language: String, completionHandler: @escaping (Result<SessionResponse, SessionResponseError>) -> Void) -> Void {
        do {
            _ = try RequestSession.shared.getSession(baseUrl: baseUrl, requestParameters: SessionRequestParameters(relyingPartyName: kRelyingPartyName, relyingPartyUUID: kRelyingPartyUUID, phoneNumber: "+\(phoneNumber)", nationalIdentityNumber: nationalIdentityNumber, hash: hash, hashType: hashType, language: language, displayText: kDisplayText, displayTextFormat: kDisplayTextFormat)) { (sessionResult) in
                
                switch sessionResult {
                case .success(let response):
//                    print(response)
                    completionHandler(.success(response))
                case .failure(let error):
                    print(error)
                    print(error.localizedDescription)
                    print(error.errorDescription)
                    completionHandler(.failure(error))
                }
            }
        } catch let error {
            print(error)
        }
    }
    
    func getMobileIDSessionStatus(baseUrl: String, process: PollingProcess, sessionId: String, timeoutMs: Int?, completionHandler: @escaping (Result<SessionStatusResponse, SessionResponseError>) -> Void ) {
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                do {
                    _ = try RequestSession.shared.getSessionStatus(baseUrl: baseUrl, process: process, requestParameters: SessionStatusRequestParameters(sessionId: sessionId, timeoutMs: timeoutMs)) { (sessionStatusResult) in
                        switch sessionStatusResult {
                        case .success(let sessionStatus):
                            if sessionStatus.state == SessionResponseState.COMPLETE {
                                timer.invalidate()
                                print("REQUEST COMPLETE")
                                print(sessionStatus)
                                completionHandler(.success(sessionStatus))
                            } else {
                                print("REQUESTING...")
                                print(sessionStatus)
                            }
                        case .failure(let sessionError):
                            print(sessionError)
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
    }

    
    private func generateHash(cert: String, digestMethod: String, signingValue: String, containerPath: String, completionHandler: @escaping (String, String, Error) -> Void) {
        if signingValue == "" {
            let signAndValidate = MoppLibManager.sharedInstance()?.signAndValidate(cert, signatureValue: signingValue, containerPath: containerPath, validate: false);
            let getDataToSign = MoppLibManager.sharedInstance()?.getDataToSign() ?? Data();
            
            
            
            print("\nVERIFICATION CODE: \(generateVerificationCode(hash: getDataToSign))\n")
            
            completionHandler(signAndValidate?.encodedDataToSign.takeUnretainedValue() as String? ?? "", "Data()", NSError(domain: "", code: 0, userInfo: ["":""]))
        } else {
            let signAndValidate = MoppLibManager.sharedInstance()?.signAndValidate(cert, signatureValue: signingValue, containerPath: containerPath, validate: true);
            
            completionHandler(signAndValidate?.encodedDataToSign.takeUnretainedValue() as String? ?? "", "Data()", NSError(domain: "", code: 0, userInfo: ["":""]))
        }
    }
    
    func generateVerificationCode(hash: Data) -> Int {
//        let binaryData: Data? = Data(hash.utf8)
        
        let stringOf01: String = hash.reduce("") { (acc, byte) -> String in
            acc + String(byte, radix: 2)
        }
        
        let firstSixBytes: Substring = stringOf01.prefix(6)
        let lastSevenBytes: Substring = stringOf01.suffix(7)
        let codeBytes: String = String(firstSixBytes) + String(lastSevenBytes)
        
        if let numberCode = Int(codeBytes, radix: 2) {
            print("\n")
            print("PIN Verification Code: \(numberCode)")
            print("\n")
            
            return numberCode
        }
        
        
        return 0
        
//        return stringOf01 != nil ? ((0xFC & stringOf01[0]) << 5) | (stringOf01[strlen(stringOf01) - 1] & 0x7F) : 0;
        
        
    }
    
    func decideLanguageBasedOnPreferredLanguages() -> String {
        var language: String = String()
        let prefLanguages = NSLocale.preferredLanguages
        for i in 0..<prefLanguages.count {
            if prefLanguages[i].hasPrefix("et-") {
                language = "EST"
                break
            }
            else if prefLanguages[i].hasPrefix("lt-") {
                language = "LIT"
                break
            }
            else if prefLanguages[i].hasPrefix("ru-") {
                language = "RUS"
                break
            }
        }
        if language.isEmpty {
            language = "ENG"
        }
        
        return language
    }
}

extension SigningContainerViewController : IdCardSignViewControllerDelegate {
    func idCardSignDidFinished(cancelled: Bool, success: Bool, error: Error?) {
        if !cancelled {
            if success {
                NotificationCenter.default.post(
                    name: .signatureCreatedFinishedNotificationName,
                    object: nil,
                    userInfo: nil)
            } else {
                guard let nsError = error as NSError? else { return }
                if nsError.code == Int(MoppLibErrorCode.moppLibErrorPinBlocked.rawValue) {
                    errorAlert(message: L(.pin2BlockedAlert))
                } else {
                    errorAlert(message: L(.genericErrorMessage))
                }
            }
        } else {
            if let error = error as? IdCardActionError {
                if error == .actionCancelled {
                    errorAlert(message: L(.signingAbortedMessage))
                }
            }
        }
    }
}


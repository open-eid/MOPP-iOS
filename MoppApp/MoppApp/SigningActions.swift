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
        getMobileIDCertificate(baseUrl: "https://dd-mid-demo.ria.ee/mid-api", phoneNumber: phoneNumber, nationalIdentityNumber: idCode) { (certificateResult: Result<CertificateResponse, CertificateResponseError>) in
            switch certificateResult {
            case .success(let certificateResponse):
                // MARK: Generate Hash
                self.generateHash(cert: certificateResponse.cert ?? "", digestMethod: kDigestMethodSHA256, containerPath: self.containerViewDelegate.getContainerPath()) { (hash, error) in
                    // MARK: Get Mobile ID Session
                    self.getMobileIDSession(baseUrl: "https://dd-mid-demo.ria.ee/mid-api", phoneNumber: phoneNumber, nationalIdentityNumber: idCode, hash: hash, hashType: kHashType, language: self.decideLanguageBasedOnPreferredLanguages()) { (sessionResult) in
                        switch sessionResult {
                        case .success(let sessionResponse):
                            print(sessionResponse)
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
                    print(response)
                    completionHandler(.success(response))
                case .failure(let error):
                    print(error)
                    print(error.localizedDescription)
                    print(error.errorDescription)
                    completionHandler(.failure(error))
                    
                    DispatchQueue.main.async {
                        //  self.dismiss(animated: false) {
                        //      let alert = UIAlertController(title: kErrorKey, message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                        //      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        //      self.present(alert, animated: true, completion: nil)
                        //  }
                        
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
                    print(response)
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
    
    private func generateHash(cert: String, digestMethod: String, containerPath: String, completionHandler: @escaping (String, Error) -> Void) {
//        MoppLibContainerActions.sharedInstance()?.openContainer(withPath: containerPath, success: { (container) in
//            for case let dataFile as MoppLibDataFile in container?.dataFiles ?? [] {
//                completionHandler(MoppLibManager.sharedInstance()?.dataFileCalculateHash(withDigestMethod: digestMethod, container: container, dataFileId: dataFile.fileId) ?? "", NSError(domain: "", code: 0, userInfo: ["Error" : "This is an error"]))
//            }
//        }, failure: { (error) in
//            completionHandler("", error ?? NSError(domain: "", code: 0, userInfo: ["Error" : "This is an error2"]))
//        })
        
        
//
//        do {
//            try MoppLibManager.sharedInstance()?.prepareData(toSign: certData, containerPath: containerPath)
//        } catch {
//            print(error)
//        }
//
                MoppLibContainerActions.sharedInstance()?.openContainer(withPath: containerPath, success: { (container) in
                    do {
                        completionHandler(try (MoppLibManager.sharedInstance()?.prepareData(toSign: cert, containerPath: container?.filePath) ?? ""), NSError(domain: "", code: 0, userInfo: ["Error" : "This is an error2"]))
                    } catch {
                        print(error)
                    }
                }, failure: { (error) in
                    completionHandler("", error ?? NSError(domain: "", code: 0, userInfo: ["Error" : "This is an error2"]))
                })
        
        
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


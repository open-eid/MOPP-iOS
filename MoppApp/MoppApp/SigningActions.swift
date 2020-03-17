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
import CommonCrypto



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
        
        MobileIDSignature.shared.createMobileIDSignature(baseUrl: Configuration.getConfiguration().MIDPROXYURL, phoneNumber: phoneNumber, nationalIdentityNumber: idCode, containerPath: self.containerViewDelegate.getContainerPath(), hashType: kHashType, language: decideLanguageBasedOnPreferredLanguages())
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

extension BinaryInteger {
    var binaryDescription: String {
        var binaryString = ""
        var internalNumber = self
        var counter = 0

        for _ in (1...self.bitWidth) {
            binaryString.insert(contentsOf: "\(internalNumber & 1)", at: binaryString.startIndex)
            internalNumber >>= 1
            counter += 1
            if counter % 4 == 0 {
                binaryString.insert(contentsOf: " ", at: binaryString.startIndex)
            }
        }

        return binaryString
    }
}

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let newLength = self.characters.count
        if newLength < toLength {
            return String(repeatElement(character, count: toLength - newLength)) + self
        } else {
            return self.substring(from: index(self.startIndex, offsetBy: newLength - toLength))
        }
    }
}

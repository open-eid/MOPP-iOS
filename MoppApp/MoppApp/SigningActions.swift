//
//  SigningActions.swift
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

import Foundation
import CommonCrypto
import SkSigningLib

protocol SigningActions {
   func startSigningProcess()
   func appendSignatureWarnings()
   func sortSignatures()
   func removeContainerSignature(signatureIndex: Int)
}

extension SigningActions where Self: SigningContainerViewController {
    
    func removeContainerSignature(signatureIndex: Int) {
        let signature = container.signatures[signatureIndex]
        confirmDeleteAlert(
            message: L(.signatureRemoveConfirmMessage),
            confirmCallback: { [weak self] (alertAction) in
                if alertAction == .cancel {
                    UIAccessibility.post(notification: .layoutChanged, argument: L(.signatureRemovalCancelled))
                } else if alertAction == .confirm {
                    self?.notificationMessages = []
                    self?.updateState(.loading)
                    MoppLibContainerActions.sharedInstance().remove(
                        signature,
                        fromContainerWithPath: self?.container.filePath,
                        success: { [weak self] container in
                            self?.updateState((self?.isCreated ?? false) ? .created : .opened)
                            self?.container.signatures.remove(at: signatureIndex)
                            UIAccessibility.post(notification: .announcement, argument: L(.signatureRemoved))
                            self?.reloadData()
                        },
                        failure: { [weak self] error in
                            self?.updateState((self?.isCreated ?? false) ? .created : .opened)
                            self?.reloadData()
                            self?.infoAlert(message: L(.generalSignatureRemovalMessage))
                        })
                }
            })
    }
    
    func startSigningProcess() {
        if signingContainerViewDelegate.isContainerSignable() {
            let signSelectionVC = getTokenFlowSelectionViewController()
            signSelectionVC.modalPresentationStyle = .overFullScreen
            LandingViewController.shared.present(signSelectionVC, animated: false, completion: nil)
        } else {
            createNewContainerForNonSignableContainerAndSign()
        }
    }
    
    func getTokenFlowSelectionViewController() -> TokenFlowSelectionViewController {
        let signSelectionVC = UIStoryboard.tokenFlow.instantiateViewController(of: TokenFlowSelectionViewController.self)
       
        signSelectionVC.mobileIdEditViewControllerDelegate = self
        signSelectionVC.smartIdEditViewControllerDelegate = self
        signSelectionVC.idCardSignViewControllerDelegate = self
        signSelectionVC.nfcEditViewControllerDelegate = self
        signSelectionVC.containerPath = containerPath
        
        return signSelectionVC
    }
    
    func appendSignatureWarnings() {
        
        if self.invalidSignaturesCount > 0 {
            var signatureWarningText: String!
            if self.invalidSignaturesCount == 1 {
                signatureWarningText = L(.containerErrorMessageInvalidSignature)
            } else if self.invalidSignaturesCount > 1 {
                signatureWarningText = L(.containerErrorMessageInvalidSignatures, [self.invalidSignaturesCount])
            }
            let signatureWarningTextNotification = NotificationMessage(isSuccess: false, text: signatureWarningText)
            if !self.notificationMessages.contains(where: { $0 == signatureWarningTextNotification }) {
                self.notificationMessages.append(signatureWarningTextNotification)
            }
        }
        
        if self.unknownSignaturesCount > 0 {
            var signatureWarningText: String!
            if self.unknownSignaturesCount == 1 {
                signatureWarningText = L(.containerErrorMessageUnknownSignature)
            } else if self.unknownSignaturesCount > 1 {
                signatureWarningText = L(.containerErrorMessageUnknownSignatures, [self.unknownSignaturesCount])
            }
            let signatureWarningTextNotification = NotificationMessage(isSuccess: false, text: signatureWarningText)
            if !self.notificationMessages.contains(where: { $0 == signatureWarningTextNotification }) {
                self.notificationMessages.append(signatureWarningTextNotification)
            }
        }
    }
    
    func sortSignatures() {
        container.signatures.sort { (sig1: MoppLibSignature, sig2: MoppLibSignature) -> Bool in
            let signatureStatusValue1 = sig1.status.rawValue
            let signatureStatusValue2 = sig2.status.rawValue
            if signatureStatusValue1 == signatureStatusValue2 {
                return sig1.timestamp < sig2.timestamp
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
        
        let mobileIDParameters = MobileIDParameters(phoneNumber: phoneNumber, idCode: idCode, containerPath: self.containerViewDelegate.getContainerPath(), hashType: kHashType, language: decideLanguageBasedOnPreferredLanguages(), roleData: DefaultsHelper.isRoleAndAddressEnabled ? RoleAndAddressUtil.getSavedRoleInfo() : nil)
        createMobileIDSignature(mobileIDParameters: mobileIDParameters)
    }
    
    func createMobileIDSignature(mobileIDParameters: MobileIDParameters) {
        let mobileIDChallengeview = UIStoryboard.tokenFlow.instantiateViewController(of: MobileIDChallengeViewController.self)
        mobileIDChallengeview.modalPresentationStyle = .overFullScreen
        present(mobileIDChallengeview, animated: false)
        MobileIDSignature.shared.createMobileIDSignature(phoneNumber: mobileIDParameters.phoneNumber, nationalIdentityNumber: mobileIDParameters.idCode, containerPath: mobileIDParameters.containerPath, hashType: mobileIDParameters.hashType, language: mobileIDParameters.language, roleData: mobileIDParameters.roleData)
    }
    
    func decideLanguageBasedOnPreferredLanguages() -> String {
        let currentLanguage = DefaultsHelper.moppLanguageID
        if currentLanguage == "et" {
            return "EST"
        } else if currentLanguage == "ru" {
            return "RUS"
        }
        return "ENG"
    }
}

extension SigningContainerViewController : SmartIDEditViewControllerDelegate {
    func smartIDEditViewControllerDidDismiss(cancelled: Bool, country: String?, idCode: String?) {
        if cancelled { return }

        guard let country = country else { return }
        guard let idCode = idCode else { return }
        
        let smartIDParameters = SmartIDParameters(country: country, idCode: idCode, containerPath: self.containerViewDelegate.getContainerPath(), hashType: kHashType, roleData: DefaultsHelper.isRoleAndAddressEnabled ? RoleAndAddressUtil.getSavedRoleInfo() : nil)
        createSmartIDSignature(smartIDParameters: smartIDParameters)
    }
    
    func createSmartIDSignature(smartIDParameters: SmartIDParameters) {
        let smartIDChallengeview = UIStoryboard.tokenFlow.instantiateViewController(of: SmartIDChallengeViewController.self)
        smartIDChallengeview.modalPresentationStyle = .overFullScreen
        present(smartIDChallengeview, animated: false)

        SmartIDSignature.shared.createSmartIDSignature(
            country: smartIDParameters.country,
            nationalIdentityNumber: smartIDParameters.idCode,
            containerPath: smartIDParameters.containerPath,
            hashType: smartIDParameters.hashType,
            roleData: smartIDParameters.roleData
        )
    }
}

extension SigningContainerViewController : NFCEditViewControllerDelegate {
    func nfcEditViewControllerDidDismiss(cancelled: Bool, can: String?, pin: String?) {
        if !cancelled, let can = can, let pin = pin {
            NFCSignature.shared.createNFCSignature(can: can, pin: pin, containerPath: self.containerViewDelegate.getContainerPath(), hashType: kHashType, roleData: DefaultsHelper.isRoleAndAddressEnabled ? RoleAndAddressUtil.getSavedRoleInfo() : nil)
        }
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
                switch nsError.code {
                case MoppLibErrorCode.moppLibErrorPinBlocked.rawValue:
                    ErrorUtil.generateError(signingError: L(.pin2BlockedAlert))
                case MoppLibErrorCode.moppLibErrorTooManyRequests.rawValue:
                    ErrorUtil.generateError(signingError: .tooManyRequests(signingMethod: SigningType.idCard.rawValue))
                case MoppLibErrorCode.moppLibErrorNoInternetConnection.rawValue:
                    ErrorUtil.generateError(signingError: .noResponseError)
                case MoppLibErrorCode.moppLibErrorOCSPTimeSlot.rawValue:
                    ErrorUtil.generateError(signingError: .ocspInvalidTimeSlot)
                case MoppLibErrorCode.moppLibErrorSslHandshakeFailed.rawValue:
                    ErrorUtil.generateError(signingError: .invalidSSLCert)
                case MoppLibErrorCode.moppLibErrorInvalidProxySettings.rawValue:
                    ErrorUtil.generateError(signingError: .invalidProxySettings)
                default:
                    ErrorUtil.generateError(signingError: .empty, details: MessageUtil.errorMessageWithDetails(details: nsError.localizedDescription))
                }
            }
        } else if let error = error as? IdCardActionError, error == .actionCancelled {
            ErrorUtil.generateError(signingError: L(.signingAbortedMessage))
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
        let newLength = self.count
        if newLength < toLength {
            return String(repeatElement(character, count: toLength - newLength)) + self
        } else {
            let strIndex = self.index(self.startIndex, offsetBy: newLength - toLength)
            return String(self[..<strIndex])
        }
    }
}

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
        guard let signature = container.signatures[signatureIndex] as? MoppLibSignature else {
            return
        }
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

        MobileIDSignature.shared.createMobileIDSignature(phoneNumber: phoneNumber, nationalIdentityNumber: idCode, containerPath: containerPath, hashType: kHashType, language: decideLanguageBasedOnPreferredLanguages(), roleData: DefaultsHelper.isRoleAndAddressEnabled ? RoleAndAddressUtil.getSavedRoleInfo() : nil)
    }
    
    func decideLanguageBasedOnPreferredLanguages() -> String {
        return switch DefaultsHelper.moppLanguageID {
        case "et": "EST"
        case "ru": "RUS"
        default: "ENG"
        }
    }
}

extension SigningContainerViewController : SmartIDEditViewControllerDelegate {
    func smartIDEditViewControllerDidDismiss(cancelled: Bool, country: String?, idCode: String?) {
        if cancelled { return }

        guard let country = country else { return }
        guard let idCode = idCode else { return }

        let smartIDChallengeview = UIStoryboard.tokenFlow.instantiateViewController(of: SmartIDChallengeViewController.self)
        smartIDChallengeview.modalPresentationStyle = .overFullScreen
        present(smartIDChallengeview, animated: false)

        SmartIDSignature.shared.createSmartIDSignature(
            country: country,
            nationalIdentityNumber: idCode,
            containerPath: containerPath,
            hashType: kHashType,
            roleData: DefaultsHelper.isRoleAndAddressEnabled ? RoleAndAddressUtil.getSavedRoleInfo() : nil
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

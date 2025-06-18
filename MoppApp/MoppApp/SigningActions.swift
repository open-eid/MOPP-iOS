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

import SkSigningLib

protocol SigningActions {
   func startSigningProcess()
   func appendSignatureWarnings()
   func removeContainerSignature(signatureIndex: Int)
}

extension SigningActions where Self: SigningContainerViewController {
    
    func removeContainerSignature(signatureIndex: Int) {
        let signature = container.signatures[signatureIndex]
        confirmDeleteAlert(message: L(.signatureRemoveConfirmMessage)) { [weak self] alertAction in
            guard alertAction == .confirm,
                let filePath = self?.container.filePath else {
                return UIAccessibility.post(notification: .layoutChanged, argument: L(.signatureRemovalCancelled))
            }
            self?.notificationMessages = []
            self?.updateState(.loading)
            MoppLibContainerActions.remove(signature, fromContainerWithPath: filePath) { error in
                guard let self else { return }
                guard error == nil else {
                    self.showLoading(show: false)
                    return self.infoAlert(message: L(.generalSignatureRemovalMessage))
                }
                self.updateState(self.isCreated ? .created : .opened)
                self.container.signatures.remove(at: signatureIndex)
                self.reloadData()
                UIAccessibility.post(notification: .announcement, argument: L(.signatureRemoved))
            }
        }
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

//
//  CryptoActions.swift
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

protocol CryptoActions {
    func startEncryptingProcess()
    func startDecryptingProcess()
}

extension CryptoActions where Self: CryptoContainerViewController {
    
    func startEncryptingProcess() {
        guard container.addressees.count > 0 else {
            return self.infoAlert(message: L(.cryptoNoAddresseesWarning))
        }
        Encrypt.encryptFile(container.filePath,
                            with: container.dataFiles,
                            with: container.addressees,
            success: {
                self.isCreated = false
                self.isForPreview = false
                self.isContainerEncrypted = true
                self.state = .loading
                self.containerViewDelegate.openContainer(afterSignatureCreated: true)
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: L(.cryptoEncryptionSuccess))
                let encryptionSuccess = NotificationMessage(isSuccess: true, text: L(.cryptoEncryptionSuccess))
                if !self.notifications.contains(where: { $0 == encryptionSuccess }) {
                    self.notifications.append(encryptionSuccess)
                }
                self.reloadCryptoData()

                MoppFileManager.removeFiles()
            },
            failure: {
                self.infoAlert(message: L(.cryptoEncryptionErrorText))
            }
        )
    }
    func startDecryptingProcess() {
        let decryptSelectionVC = UIStoryboard.tokenFlow.instantiateViewController(of: TokenFlowSelectionViewController.self)
        decryptSelectionVC.modalPresentationStyle = .overFullScreen
        
        decryptSelectionVC.idCardDecryptViewControllerDelegate = self
        decryptSelectionVC.containerPath = containerPath
        decryptSelectionVC.isFlowForDecrypting = true
        LandingViewController.shared.present(decryptSelectionVC, animated: false, completion: nil)
    }
}

extension CryptoContainerViewController : IdCardDecryptViewControllerDelegate {
    
    func idCardDecryptDidFinished(cancelled: Bool, success: Bool, dataFiles: [String: Data], error: Error?) {
        if !cancelled {
            if success {
                container.dataFiles.removeAll()
                for dataFile in dataFiles {
                    guard let destinationPath = MoppFileManager.shared.tempFilePath(withFileName: dataFile.key) else {
                        dismiss(animated: false)
                        infoAlert(message: L(.decryptionErrorMessage))
                        return
                    }
                    container.dataFiles.append(CryptoDataFile(filename: dataFile.key, filePath: destinationPath))
                    MoppFileManager.shared.createFile(atPath: destinationPath, contents: dataFile.value)
                }
                
                self.isCreated = false
                self.isForPreview = false
                self.dismiss(animated: false)
                self.isDecrypted = true
                self.isContainerEncrypted = false
                
                let decryptionSuccess = NotificationMessage(isSuccess: true, text: L(.containerDetailsDecryptionSuccess))
                if !self.notifications.contains(where: { $0 == decryptionSuccess }) {
                    self.notifications.append(decryptionSuccess)
                }
                UIAccessibility.post(notification: .screenChanged, argument: L(.containerDetailsDecryptionSuccess))
                
                self.reloadCryptoData()
            } else {
                self.dismiss(animated: false)
                guard let nsError = error as NSError? else { return }
                if nsError.code == MoppLibErrorCode.moppLibErrorPinBlocked.rawValue {
                    errorAlertWithLink(message: L(.pin1BlockedAlert))
                } else {
                    infoAlert(message: L(.decryptionErrorMessage))
                }
            }
        }
    }
    
    
    
}

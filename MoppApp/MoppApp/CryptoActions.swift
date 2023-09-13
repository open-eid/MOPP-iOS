//
//  CryptoActions.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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
        if container.addressees.count > 0 {
            MoppLibCryptoActions.sharedInstance().encryptData(
                container.filePath as String?,
                withDataFiles: container.dataFiles as? [Any],
                withAddressees: container.addressees as? [Any],
                success: {
                    self.isCreated = false
                    self.isForPreview = false
                    self.isContainerEncrypted = true
                    self.state = .loading
                    self.containerViewDelegate.openContainer(afterSignatureCreated: true)
                    UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: L(.cryptoEncryptionSuccess))
                    self.notifications.append(NotificationMessage(isSuccess: true, text: L(.cryptoEncryptionSuccess)))
                    self.reloadCryptoData()
                    
                    if !DefaultsHelper.hideShareContainerDialog {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.displayShareContainerDialog()
                        }
                    }
                    
            },
                failure: { _ in
                    DispatchQueue.main.async {
                        self.infoAlert(message: L(.cryptoEncryptionErrorText), title: L(.errorAlertTitleGeneral))
                    }
                }
            )
        } else {
            self.infoAlert(message: L(.cryptoNoAddresseesWarning), title: L(.errorAlertTitleGeneral))
        }
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
    
    func idCardDecryptDidFinished(cancelled: Bool, success: Bool, dataFiles: NSMutableDictionary, error: Error?) {
        if !cancelled {
            if success {
                container.dataFiles.removeAllObjects()
                for dataFile in dataFiles {
                    let cryptoDataFile = CryptoDataFile()
                    cryptoDataFile.filename = dataFile.key as? String
                    guard let destinationPath = MoppFileManager.shared.tempFilePath(withFileName: cryptoDataFile.filename) else {
                        dismiss(animated: false)
                        infoAlert(message: L(.decryptionErrorMessage), title: L(.errorAlertTitleGeneral))
                        return
                    }
                    cryptoDataFile.filePath = destinationPath
                    container.dataFiles.add(cryptoDataFile)
                    MoppFileManager.shared.createFile(atPath: destinationPath, contents: dataFile.value as! Data)
                }
                
                self.isCreated = false
                self.isForPreview = false
                self.dismiss(animated: false)
                self.isDecrypted = true
                self.isContainerEncrypted = false
                
                self.notifications.append(NotificationMessage(isSuccess: true, text: L(.containerDetailsDecryptionSuccess)))
                UIAccessibility.post(notification: .screenChanged, argument: L(.containerDetailsDecryptionSuccess))
                
                self.reloadCryptoData()
            } else {
                self.dismiss(animated: false)
                guard let nsError = error as NSError? else { return }
                if nsError.code == Int(MoppLibErrorCode.moppLibErrorPinBlocked.rawValue) {
                    errorAlertWithLink(message: L(.pin1BlockedAlert))
                } else {
                    infoAlert(message: L(.decryptionErrorMessage), title: L(.errorAlertTitleGeneral))
                }
            }
        }
    }
    
    
    
}

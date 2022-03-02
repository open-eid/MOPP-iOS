//
//  SigningContainerViewController.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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
import MoppLib
import UIKit

class SigningContainerViewController : ContainerViewController, SigningActions, UIDocumentPickerDelegate {
    
    var container: MoppLibContainer!
    var invalidSignaturesCount: Int {
        if container == nil { return 0 }
        return (container.signatures as! [MoppLibSignature]).filter { (MoppLibSignatureStatus.Invalid == $0.status) }.count
    }
    
    var unknownSignaturesCount: Int {
        if container == nil { return 0 }
        return (container.signatures as! [MoppLibSignature]).filter { (MoppLibSignatureStatus.UnknownStatus == $0.status) }.count
    }
    
   override class func instantiate() -> SigningContainerViewController {
       return UIStoryboard.container.instantiateInitialViewController(of: SigningContainerViewController.self)
   }
    
   override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        landingViewController.isAlreadyInMainPage = false
        containerViewDelegate = self
        signingContainerViewDelegate = self
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension SigningContainerViewController : SigningContainerViewControllerDelegate {
    
    func removeSignature(index: Int) {
        removeContainerSignature(signatureIndex: index)
    }
    
    func getSignature(index: Int) -> Any {
        return container.signatures[index]
    }
    
    func getTimestampToken(index: Int) -> Any {
        return container.timestampTokens[index]
    }
    
    func startSigning() {
        startSigningProcess()
    }
    
    func getSignaturesCount() -> Int {
        if isContainerEmpty() {
            return 0
        }
        return container.signatures.count
    }
    
    func getTimestampTokensCount() -> Int {
        if isContainerEmpty() {
            return 0
        }
        return container.timestampTokens.count
    }
    
    func isContainerSignable() -> Bool {
        if isContainerEmpty() {
            return true
        }
        return container.isSignable()
    }
}

extension SigningContainerViewController : ContainerViewControllerDelegate {
    
    func removeDataFile(index: Int) {
        let containerFileCount: Int = self.containerViewDelegate.getDataFileCount()
        guard containerFileCount > 0 else {
            NSLog("No files in container")
            self.errorAlert(message: L(.genericErrorMessage))
            return
        }
        
        if containerFileCount == 1 {
            confirmDeleteAlert(message: L(.lastDatafileRemoveConfirmMessage)) { [weak self] (alertAction) in
                if alertAction == .cancel {
                    UIAccessibility.post(notification: .layoutChanged, argument: L(.dataFileRemovalCancelled))
                } else if alertAction == .confirm {
                    let containerPath: String? = self?.getContainerPath()
                    let isDeleted: Bool = ContainerRemovalActions.shared.removeAsicContainer(containerPath: containerPath)
                    if !isDeleted {
                        self?.errorAlert(message: L(.dataFileRemovalFailed))
                        return
                    }
                    
                    UIAccessibility.post(notification: .announcement, argument: L(.dataFileRemoved))
                    self?.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
        
        confirmDeleteAlert(
            message: L(.datafileRemoveConfirmMessage),
            confirmCallback: { [weak self] (alertAction) in
                if alertAction == .cancel {
                    UIAccessibility.post(notification: .layoutChanged, argument: L(.dataFileRemovalCancelled))
                } else if alertAction == .confirm {
                    self?.notifications = []
                    self?.updateState(.loading)
                    MoppLibContainerActions.sharedInstance().removeDataFileFromContainer(
                        withPath: self?.containerPath,
                        at: UInt(index),
                        success: { [weak self] container in
                            self?.updateState((self?.isCreated ?? false) ? .created : .opened)
                            self?.container.dataFiles.remove(at: index)
                            UIAccessibility.post(notification: .announcement, argument: L(.dataFileRemoved))
                            self?.reloadData()
                        },
                        failure: { [weak self] error in
                            self?.updateState((self?.isCreated ?? false) ? .created : .opened)
                            self?.reloadData()
                            self?.errorAlert(message: L(.dataFileRemovalFailed))
                        })
                }
            })
    }
    
    func saveDataFile(name: String?, containerPath: String?) {
        var saveFileFromContainerPath = self.containerPath
        if let dataFileContainerPath = containerPath, !dataFileContainerPath.isEmpty {
            saveFileFromContainerPath = dataFileContainerPath
        }
        SaveableContainer(signingContainerPath: saveFileFromContainerPath ?? "").saveDataFile(name: name, completionHandler: { [weak self] tempSavedFileLocation, isSuccess in
            if isSuccess && !tempSavedFileLocation.isEmpty {
                // Show file save location picker
                let pickerController = UIDocumentPickerViewController(url: URL(fileURLWithPath: tempSavedFileLocation), in: .exportToService)
                pickerController.delegate = self
                self?.present(pickerController, animated: true) {
                    NSLog("Showing file saving location picker")
                }
                return
            } else {
                NSLog("Failed to save \(name ?? "file") to 'Saved Files' directory")
                self?.errorAlert(message: L(.fileImportFailedFileSave))
                return
            }
        })
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if SaveableContainer.isFileSaved(urls: urls) {
            let savedFileLocation: URL? = urls.first
            NSLog("File export done. Location: \(savedFileLocation?.path ?? "Not available")")
            self.errorAlert(message: L(.fileImportFileSaved))
        } else {
            NSLog("Failed to save file")
            return self.errorAlert(message: L(.fileImportFailedFileSave))
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        NSLog("File saving cancelled")
    }
    
    func getDataFileDisplayName(index: Int) -> String? {
        guard let dataFile = container.dataFiles[index] as? MoppLibDataFile else {
            return nil
        }
        return MoppLibManager.sanitize((dataFile.fileName as String))
    }
    
    func getContainer() -> MoppLibContainer {
        return container
    }
    
    func getContainerPath() -> String {
        return container.filePath
    }
    
    func getDataFileRelativePath(index: Int) -> String {
        return (container.dataFiles as! [MoppLibDataFile])[index].fileName
    }
    
    func getDataFileCount() -> Int {
        return container.dataFiles.count
    }
    
    func getContainerFilename() -> String {
        return container.fileName
    }
    
    func isContainerEmpty() -> Bool {
        if container == nil {
            return true
        }
        return false
    }
    
    func openContainer(afterSignatureCreated: Bool = false) {
        if state != .loading { return }
        let isPDF = containerPath.filenameComponents().ext.lowercased() == ContainerFormatPDF
        forcePDFContentPreview = isPDF
        MoppLibContainerActions.sharedInstance().openContainer(withPath: containerPath, success: { [weak self] container in
            guard let container = container else {
                return
            }
            
            guard let strongSelf = self else { return }
            
            strongSelf.notifications = []
            
            if afterSignatureCreated && container.isSignable() && !strongSelf.isForPreview {
                strongSelf.notifications.append((true, L(.containerDetailsSigningSuccess)))
                
                if UIAccessibility.isVoiceOverRunning {
                    UIAccessibility.post(notification: .screenChanged, argument: L(.containerDetailsSigningSuccess))
                }
                
                if !DefaultsHelper.hideShareContainerDialog {
                    strongSelf.displayShareContainerDialog()
                }
            }
            
            strongSelf.sections = ContainerViewController.sectionsDefault
            
            strongSelf.container = container
            strongSelf.appendSignatureWarnings()
            strongSelf.sortSignatures()
            // State cannot change if back button is pressed
            if(strongSelf.landingViewController.isAlreadyInMainPage == false){
                strongSelf.updateState((self?.isCreated ?? false) ? .created : .opened)
                strongSelf.reloadData()
            } else {
                strongSelf.landingViewController.isAlreadyInMainPage = false
            }
            
            if strongSelf.startSigningWhenOpened {
                strongSelf.startSigningWhenOpened = false
                strongSelf.startSigningProcess()
            }
            
            }, failure: { [weak self] error in
                
                let nserror = error! as NSError
                var message = nserror.domain
                var title: String? = nil
                if nserror.code == Int(MoppLibErrorCode.moppLibErrorGeneral.rawValue) {
                    title = L(.fileImportOpenExistingFailedAlertTitle)
                    message = L(.fileImportOpenExistingFailedAlertMessage, [self?.containerPath.substr(fromLast: "/") ?? String()])
                } else if nserror.code == Int(MoppLibErrorCode.moppLibErrorNoInternetConnection.rawValue) {
                    message = L(.noConnectionMessage)
                }
                self?.errorAlert(message: message, title: title, dismissCallback: { _ in
                    _ = self?.navigationController?.popViewController(animated: true)
                });
        })
    }
    

}

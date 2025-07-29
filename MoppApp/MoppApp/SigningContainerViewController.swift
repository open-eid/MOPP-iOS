//
//  SigningContainerViewController.swift
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

class SigningContainerViewController : ContainerViewController, SigningActions {
    
    var container: MoppLibContainer!
    var notificationMessages: [NotificationMessage] = []
    var invalidSignaturesCount: Int {
        if container == nil { return 0 }
        return container.signatures.filter { (MoppLibSignatureStatus.Invalid == $0.status) }.count
    }
    
    var unknownSignaturesCount: Int {
        if container == nil { return 0 }
        return container.signatures.filter { (MoppLibSignatureStatus.UnknownStatus == $0.status) }.count
    }
    
   override class func instantiate() -> SigningContainerViewController {
       return UIStoryboard.container.instantiateInitialViewController(of: SigningContainerViewController.self)
   }
    
    func reloadNotifications() {
        // Don't add duplicate notification messages
        for (index, notificationMessage) in notificationMessages.enumerated() {
            if !self.notifications.contains(where: { $0.isSuccess == notificationMessage.isSuccess && $0.text == notificationMessage.text }) {
                self.notifications.append(notificationMessage)
                if notificationMessage.isSuccess {
                    notificationMessages.remove(at: index)
                }
            }
        }
        
        self.reloadData()
    }
    
   override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
       reloadNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        landingViewController.isAlreadyInMainPage = false
        containerViewDelegate = self
        signingContainerViewDelegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(receiveErrorNotification), name: .errorNotificationName, object: nil)
        
        if UIAccessibility.isVoiceOverRunning {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didFinishAnnouncement(_:)),
                name: UIAccessibility.announcementDidFinishNotification,
                object: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIAccessibility.announcementDidFinishNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension SigningContainerViewController : SigningContainerViewControllerDelegate {
    
    func removeSignature(index: Int) {
        removeContainerSignature(signatureIndex: index)
    }
    
    func getSignature(index: Int) -> MoppLibSignature {
        return container.signatures[index]
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
    
    func isContainerSignable() -> Bool {
        if isContainerEmpty() {
            return true
        }
        return container.isSignable
    }
    
    func isCades() -> Bool {
        container.isCades
    }
}

extension SigningContainerViewController : ContainerViewControllerDelegate {
    
    func removeDataFile(index: Int) {
        let containerFileCount: Int = self.containerViewDelegate.getDataFileCount()
        guard containerFileCount > 0 else {
            printLog("No files in container")
            self.infoAlert(message: "File not found in container")
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
                        self?.infoAlert(message: L(.dataFileRemovalFailed))
                        return
                    }
                    if UIAccessibility.isVoiceOverRunning {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            UIAccessibility.post(notification: .screenChanged, argument: L(.dataFileRemoved))
                        }
                    }
                    self?.navigationController?.popToRootViewController(animated: true)
                }
            }
        }

        confirmDeleteAlert(message: L(.datafileRemoveConfirmMessage)) { [weak self] alertAction in
            guard alertAction == .confirm,
                let containerPath = self?.containerPath else {
                return UIAccessibility.post(notification: .layoutChanged, argument: L(.dataFileRemovalCancelled))
            }
            self?.notificationMessages = []
            self?.updateState(.loading)
            MoppLibContainerActions.removeDataFileFromContainer(withPath: containerPath, at: UInt(index)) { [weak self] error in
                guard let self else { return }
                guard error == nil else {
                    self.showLoading(show: false)
                    return self.infoAlert(message: L(.dataFileRemovalFailed))
                }
                self.updateState(self.isCreated ? .created : .opened)
                self.container.dataFiles.remove(at: index)
                self.reloadData()
                if UIAccessibility.isVoiceOverRunning {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        UIAccessibility.post(notification: .screenChanged, argument: L(.dataFileRemoved))
                    }
                }
            }
        }
    }
    
    func saveDataFile(name: String?, containerPath: String?) {
        var saveFileFromContainerPath = self.containerPath
        if let dataFileContainerPath = containerPath, !dataFileContainerPath.isEmpty {
            saveFileFromContainerPath = dataFileContainerPath
        }
        SaveableContainer(signingContainerPath: saveFileFromContainerPath ?? "").saveDataFile(name: name, completionHandler: { [weak self] tempSavedFileLocation, isSuccess in
            if isSuccess && !tempSavedFileLocation.isEmpty {
                // Show file save location picker
                let pickerController = UIDocumentPickerViewController(forExporting: [URL(fileURLWithPath: tempSavedFileLocation)], asCopy: true)
                pickerController.delegate = self
                self?.present(pickerController, animated: true) {
                    printLog("Showing file saving location picker")
                }
                return
            } else {
                printLog("Failed to save \(name ?? "file") to 'Saved Files' directory")
                self?.infoAlert(message: L(.fileImportFailedFileSave))
                return
            }
        })
    }
    
    func getDataFileDisplayName(index: Int) -> String? {
        container.dataFiles[index].fileName
    }
    
    func getContainer() -> MoppLibContainer {
        return container
    }
    
    func getContainerPath() -> String {
        return container.filePath
    }
    
    func getDataFileRelativePath(index: Int) -> String {
        container.dataFiles[index].fileName
    }
    
    func getDataFileCount() -> Int {
        return container.dataFiles.count
    }
    
    func getContainerFilename() -> String {
        return container.fileName
    }
    
    func isContainerEmpty() -> Bool {
        container == nil
    }
    
    func openContainer(afterSignatureCreated: Bool = false) {
        if state != .loading { return }
        let isPDF = containerPath.filenameComponents().ext.lowercased() == ContainerFormatPDF
        forcePDFContentPreview = isPDF
        MoppLibContainerActions.openContainer(withPath: containerPath) { [weak self] container, error in

            if let error {
                let nserror = error as NSError
                var message = nserror.localizedDescription
                switch nserror {
                case .general:
                    message = L(.fileImportOpenExistingFailedAlertMessage, [self?.containerPath.substr(fromLast: "/") ?? String()])
                case .noInternetConnection:
                    message = L(.noConnectionMessage)
                case .invalidProxySettings:
                    message = L(.proxyUnableToConnectToService)
                default: break
                }
                self?.infoAlert(message: message) { _ in
                    _ = self?.navigationController?.popViewController(animated: true)
                }
                return
            }

            guard let strongSelf = self else { return }
            
            strongSelf.notificationMessages = []
            
            if afterSignatureCreated && container!.isSignable && !strongSelf.isForPreview {
                let signingSuccessNotification = NotificationMessage(isSuccess: true, text: L(.containerDetailsSigningSuccess))
                if !strongSelf.notificationMessages.contains(where: { $0 == signingSuccessNotification }) {
                    strongSelf.notificationMessages.append(signingSuccessNotification)
                }
                
                if UIAccessibility.isVoiceOverRunning {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        let message: NSAttributedString = NSAttributedString(string: L(.containerDetailsSigningSuccess), attributes: [.accessibilitySpeechQueueAnnouncement: true])
                        UIAccessibility.post(notification: .announcement, argument: message)
                    }
                }
                
                MoppFileManager.removeFiles()
            }
            
            strongSelf.sections = ContainerViewController.sectionsDefault
            
            strongSelf.container = container
            strongSelf.appendSignatureWarnings()
            if !strongSelf.notificationMessages.isEmpty {
                strongSelf.reloadNotifications()
            }
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
        }
    }
    
    @objc func didFinishAnnouncement(_ notification: Notification) {
        let announcementValue: String? = notification.userInfo?[UIAccessibility.announcementStringValueUserInfoKey] as? String
        let isAnnouncementSuccessful: Bool? = notification.userInfo?[UIAccessibility.announcementWasSuccessfulUserInfoKey] as? Bool
        
        guard let isSuccessful = isAnnouncementSuccessful else {
            return
        }
        
        if !isSuccessful && announcementValue == L(.containerDetailsSigningSuccess) {
            printLog("Signature added announcement was not successful, retrying...")
            UIAccessibility.post(notification: .announcement, argument: announcementValue)
        } else if isSuccessful && announcementValue == L(.containerDetailsSigningSuccess) {
            NotificationCenter.default.removeObserver(self, name: UIAccessibility.announcementDidFinishNotification, object: nil)
        }
    }
    
    @objc func receiveErrorNotification(_ notification: Notification) {
        if !isNFCCancelled(notification: notification) {
            DispatchQueue.main.async {
                self.dismiss(animated: false) {
                    let topViewController = self.getTopViewController()
                    AlertUtil.errorMessageDialog(notification, topViewController: topViewController)
                }
            }
        }
    }
    
    func isNFCCancelled(notification: Notification) -> Bool {
        guard let userInfo = notification.userInfo else { return false }
        let error = userInfo[kErrorKey] as? NSError
        let signingError = error?.userInfo[NSLocalizedDescriptionKey] as? SigningError
        
        guard let signError = signingError, signError == .nfcCancelled else {
            return false
        }
        return true
    }
}

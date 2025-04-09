//
//  CryptoContainerViewController.swift
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

import UIKit
import CryptoLib

class CryptoContainerViewController : ContainerViewController, CryptoActions {

    var container: CryptoContainer!
    weak var delegate: AddresseeViewControllerDelegate?
    var isContainerEncrypted = false
    override class func instantiate() -> CryptoContainerViewController {
        return UIStoryboard.container.instantiateViewController(of: CryptoContainerViewController.self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func reloadCryptoData() {
        
        self.isEncrypted = isContainerEncrypted
        
        if container != nil && container.addressees.count > 0 && (state == .opened || isContainerEncrypted) {
            self.sections = ContainerViewController.sectionsEncrypted
        } else if container != nil && container.addressees.count > 0 {
            self.sections = ContainerViewController.sectionsWithAddresses
        } else {
            self.sections = ContainerViewController.sectionsNoAddresses
        }
        self.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        containerViewDelegate = self
        cryptoContainerViewDelegate = self
        delegate = self
        reloadCryptoData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        printLog("Deinit CryptoContainerViewController")
        MoppFileManager.removeFiles()
    }
}

extension CryptoContainerViewController : CryptoContainerViewControllerDelegate {
    func startDecrypting() {
        startDecryptingProcess()
    }
    
    func startEncrypting() {
        startEncryptingProcess()
    }
    
    func getContainer() -> CryptoContainer {
        return container
    }
    
    func removeSelectedAddressee(index: Int) {
        container.addressees.remove(at: index)
        reloadCryptoData()
    }
    
    func getAddressee(index: Int) -> Any {
        return container.addressees[index]
    }
    
    func getAddresseeCount() -> Int {
        return container.addressees.count
    }
    
    func addAddressees() {
        let addresseeController = UIStoryboard.container.instantiateViewController(of: AddresseeViewController.self)
        addresseeController.addresseeViewControllerDelegate = self
        addresseeController.selectedAddressees = container.addressees
        landingViewController.importProgressViewController.dismissRecursively(animated: false, completion: {
            self.navigationController?.pushViewController(addresseeController, animated: true)
        })
    }
}

extension CryptoContainerViewController : AddresseeViewControllerDelegate {
    func addAddresseeToContainer(selectedAddressees: [Addressee]) {
        container.addressees = selectedAddressees
        self.navigationController?.popViewController(animated: true)
        reloadCryptoData()
    }
}

extension CryptoContainerViewController : ContainerViewControllerDelegate {
    
    func removeDataFile(index: Int) {
        let containerFileCount: Int = self.getContainer().dataFiles.count
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
                    let cryptoContainer: CryptoContainer? = self?.getContainer()
                    let isDeleted: Bool = ContainerRemovalActions.shared.removeCdocContainer(cryptoContainer: cryptoContainer)
                    if !isDeleted {
                        self?.infoAlert(message: L(.dataFileRemovalFailed))
                        return
                    }
                    if UIAccessibility.isVoiceOverRunning {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            UIAccessibility.post(notification: .layoutChanged, argument: L(.dataFileRemoved))
                        }
                    }
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
                    guard let strongSelf = self else { return }
                    strongSelf.notifications = []
                    strongSelf.updateState(.loading)
                    strongSelf.updateState((self?.isCreated)! ? .created : .opened)
                    if strongSelf.container.dataFiles.count > index {
                        strongSelf.container.dataFiles.removeObject(at: index)
                    } else {
                        self?.infoAlert(message: L(.dataFileRemovalFailed))
                        return
                    }
                    if UIAccessibility.isVoiceOverRunning {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            UIAccessibility.post(notification: .layoutChanged, argument: L(.dataFileRemoved))
                        }
                    }
                    strongSelf.reloadData()
                }
            })

    }
    
    func saveDataFile(name: String?, containerPath: String?) {
        var saveFileFromContainerPath = self.containerPath
        if let dataFileContainerPath = containerPath, !dataFileContainerPath.isEmpty {
            saveFileFromContainerPath = dataFileContainerPath
        }
        SaveableContainer(signingContainerPath: saveFileFromContainerPath ?? "", cryptoContainer: container).saveDataFile(name: name, completionHandler: { tempSavedFileLocation, isSuccess in
            if isSuccess && !tempSavedFileLocation.isEmpty {
                // Show file save location picker
                let pickerController = UIDocumentPickerViewController(forExporting: [URL(fileURLWithPath: tempSavedFileLocation)], asCopy: true)
                pickerController.delegate = self
                self.present(pickerController, animated: true) {
                    printLog("Showing file saving location picker")
                }
            } else {
                printLog("Failed to save \(name ?? "file") to 'Saved Files' directory")
                return self.infoAlert(message: L(.fileImportFailedFileSave))
            }
        })
    }
    
    func getDataFileDisplayName(index: Int) -> String? {
        guard let dataFile =  (container.dataFiles[index] as? CryptoDataFile) else {
            return nil
        }
        if dataFile.filePath == nil {
            return dataFile.filename
        }
        return (dataFile.filePath as NSString).lastPathComponent
    }
    
    func getContainer() -> MoppLibContainer {
        return MoppLibContainer()
    }
    
    func getContainerPath() -> String {
        return container.filePath as String
    }
    
    func getDataFileCount() -> Int {
        return container.dataFiles.count
    }
    
    func openContainer(afterSignatureCreated: Bool = false) {
        
        if state != .loading { return }
        if container == nil {
            let filePath = containerPath as NSString
            let container = CryptoContainer(filename: filePath.lastPathComponent as NSString, filePath: filePath)
            MoppLibCryptoActions.parseCdocInfo(
                filePath as String?,
                success: { cdocInfo in
                    container.addressees = cdocInfo.addressees as? [Addressee] ?? []
                    container.dataFiles = cdocInfo.dataFiles
                    self.containerPath = filePath as String?
                    self.state = .opened
                    
                    self.container = container
                    self.isDecrypted = false
                    self.reloadCryptoData()
            },
                failure: { _ in
                    DispatchQueue.main.async {
                        self.infoAlert(message: L(.fileImportOpenExistingFailedAlertMessage, [filePath.lastPathComponent]))
                    }
                }
            )
           
        }
        self.notifications = []
        self.updateState(self.isCreated ? .created : .opened)
    }
    
    func getContainerFilename() -> String {
        return container.filename as String
    }
    
    func getDataFileRelativePath(index: Int) -> String {
        return (container.dataFiles[index] as! CryptoDataFile).filename! as String
    }
    
    func isContainerEmpty() -> Bool {
        return container == nil
    }
    

}

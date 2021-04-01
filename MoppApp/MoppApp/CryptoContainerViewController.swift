//
//  CryptoContainerViewController.swift
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


class CryptoContainerViewController : ContainerViewController, CryptoActions, UIDocumentPickerDelegate {

    var container: CryptoContainer!
    var delegate: AddresseeViewControllerDelegate?
    var isContainerEncrypted = false
    override class func instantiate() -> CryptoContainerViewController {
        return UIStoryboard.container.instantiateViewController(of: CryptoContainerViewController.self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func reloadCryptoData() {
        
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
}

extension CryptoContainerViewController : CryptoContainerViewControllerDelegate {
    func startDecrypting() {
        startDecryptingProcess()
    }
    
    func startEncrypting() {
        startEncryptingProcess()
    }
    
    func removeSelectedAddressee(index: Int) {
        container.addressees.removeObject(at: index)
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
    func addAddresseeToContainer(selectedAddressees: NSMutableArray) {
        container.addressees = selectedAddressees
        self.navigationController?.popViewController(animated: true)
        reloadCryptoData()
    }
}

extension CryptoContainerViewController : ContainerViewControllerDelegate {
    
    func removeDataFile(index: Int) {
        confirmDeleteAlert(
            message: L(.datafileRemoveConfirmMessage),
            confirmCallback: { [weak self] (alertAction) in
                guard let strongSelf = self else { return }
                strongSelf.notifications = []
                strongSelf.updateState(.loading)
                strongSelf.updateState((self?.isCreated)! ? .created : .opened)
                strongSelf.container.dataFiles.removeObject(at:index)
                strongSelf.reloadData()
        })

    }
    
    func saveDataFile(name: String?) {
        guard let name = name, container != nil else {
            NSLog("Failed to get filename or file does not exist in container");
            return self.errorAlert(message: L(.fileImportFailedFileSave))
        }
        
        MoppFileManager.shared.saveFile(containerPath: self.containerPath, fileName: name, completionHandler: { (isSaved: Bool, tempSavedFileLocation: String?) in
            if isSaved {
                guard let tempSavedFileLocation = tempSavedFileLocation, MoppFileManager.shared.fileExists(tempSavedFileLocation) else {
                    NSLog("Failed to get saved temp file location or file does not exist")
                    return self.errorAlert(message: L(.fileImportFailedFileSave))
                }
                
                NSLog("Exporting to user chosen location")
                
                // Show file save location picker
                let pickerController = UIDocumentPickerViewController(url: URL(fileURLWithPath: tempSavedFileLocation), in: .exportToService)
                pickerController.delegate = self
                self.present(pickerController, animated: true) {
                    NSLog("Showing file saving location picker")
                }
            } else {
                NSLog("Failed to save \(name) to 'Saved Files' directory")
                return self.errorAlert(message: L(.fileImportFailedFileSave))
            }
        })
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if !urls.isEmpty {
            let savedFileLocation: URL? = urls.first
            NSLog("File export done. Location: \(savedFileLocation?.path ?? "Not available")")
            self.errorAlert(message: L(.fileImportFileSaved))
        }
        return
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        NSLog("File saving cancelled")
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
            MoppLibCryptoActions.sharedInstance().parseCdocInfo(
                filePath as String?,
                success: {(_ cdocInfo: CdocInfo?) -> Void in
                    guard let strongCdocInfo = cdocInfo else { return }
                    
                    container.addressees = strongCdocInfo.addressees
                    container.dataFiles = strongCdocInfo.dataFiles
                    self.containerPath = filePath as String?
                    self.state = .opened
                    
                    self.container = container
                    self.isDecrypted = false
                    self.reloadCryptoData()
            },
                failure: { _ in
                    DispatchQueue.main.async {
                        self.errorAlert(message: L(.fileImportOpenExistingFailedAlertMessage, [filePath.lastPathComponent]))
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

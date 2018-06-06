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


class CryptoContainerViewController : ContainerViewController, CryptoActions {

    var container: CryptoContainer!
    var delegate: AddresseeViewControllerDelegate?
    
    override class func instantiate() -> CryptoContainerViewController {
        return UIStoryboard.container.instantiateViewController(of: CryptoContainerViewController.self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func reloadCryptoData() {
        if container.addressees.count > 0 && state == .opened {
            self.sections = ContainerViewController.sectionsEncrypted
        } else if container.addressees.count > 0 {
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
        if container == nil {
            self.sections = ContainerViewController.sectionsEncrypted
        } else {
            self.sections = ContainerViewController.sectionsNoAddresses
        }
        
    }
}

extension CryptoContainerViewController : CryptoContainerViewControllerDelegate {
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
    
    func getDataFileOriginFilename(index: Int) -> String {
        guard let dataFile =  (container.dataFiles[index] as? CryptoDataFile) else {
            return ""
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
            let containerFilename = (containerPath as NSString).lastPathComponent
            container = CryptoContainer.init(filename: containerFilename as NSString, filePath: containerPath as NSString)
            self.reloadData()
        }
        self.notifications = []
        self.updateState(self.isCreated ? .created : .opened)
    }
    
    func getContainerFilename() -> String {
        return container.filename as String
    }
    
    func getDataFileFilename(index: Int) -> String {
        return (container.dataFiles[index] as! CryptoDataFile).filename! as String
    }
    
    func isContainerEmpty() -> Bool {
        return container == nil
    }
    

}

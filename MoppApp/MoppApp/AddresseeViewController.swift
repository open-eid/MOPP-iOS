//
//  AddresseeViewController.swift
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

protocol AddresseeViewControllerDelegate: class {
    func addAddresseeToContainer(selectedAddressees: NSMutableArray)
}

class AddresseeViewController : MoppViewController {
    weak var addresseeViewControllerDelegate: AddresseeViewControllerDelegate? = nil
    @IBOutlet weak var tableView: UITableView!

    
    enum Section {
        case notifications
        case search
        case searchResult
        case addressees
    }
    
    var foundAddressees: NSArray = []
    var selectedAddressees: NSMutableArray = []
    var notifications: [(isSuccess: Bool, text: String)] = []
    var selectedIndexes: NSMutableArray = []
    
    var sectionHeaderTitle: [Section: String] = [
        .addressees  : L(LocKey.containerHeaderCreateAddresseesTitle),
    ]
    
    internal static let sectionsDefault  : [Section] = [.notifications, .search, .searchResult, .addressees]
    
    var sections: [Section] = AddresseeViewController.sectionsDefault
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationItemForPushedViewController(title: L(.containerAddresseeTitle))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dismissKeyboard()
        LandingViewController.shared.tabButtonsDelegate = self
        LandingViewController.shared.presentButtons([.confirmButton])
    }
    
    private func dismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
   
}

extension AddresseeViewController : UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        selectedIndexes = []
        showLoading(show: true)
        MoppLibCryptoActions.sharedInstance().searchLdapData(
            searchBar.text,
            success: { (_ ldapResponse: NSMutableArray?) -> Void in
                _ = ldapResponse?.sorted {($0 as! Addressee).identifier < ($1 as! Addressee).identifier }
                
                self.foundAddressees = (ldapResponse?.sorted {($0 as! Addressee).identifier < ($1 as! Addressee).identifier } as! NSArray)
                self.showLoading(show: false)
                self.tableView.reloadData()
            },
            failure: { error in
                guard let nsError = error as NSError? else { return }
                DispatchQueue.main.async {
                    if nsError.code == Int(MoppLibErrorCode.moppLibErrorNoInternetConnection.rawValue) {
                        self.errorAlert(message: L(.noConnectionMessage))
                    } else {
                        self.errorAlert(message: L(.cryptoEmptyLdapLabel))
                    }
                    self.showLoading(show: false)
                }
        }, configuration: MoppLDAPConfiguration.getMoppLDAPConfiguration()
        )
    }
}


extension AddresseeViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
            case .notifications:
                return notifications.count
            case .search:
                return 1
            case .searchResult:
                return foundAddressees.count
            case .addressees:
                return selectedAddressees.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        switch sections[indexPath.section] {
            case .notifications:
                let cell = tableView.dequeueReusableCell(withType: ContainerNotificationCell.self, for: indexPath)!
                cell.populate(isSuccess: notifications[row].isSuccess, text: notifications[row].text)
                return cell
            case .search:
                let cell = tableView.dequeueReusableCell(withType: ContainerSearchCell.self, for: indexPath)!
                return cell
            case .searchResult:
                let cell = tableView.dequeueReusableCell(withType: ContainerFoundAddresseeCell.self, for: indexPath)!
                cell.delegate = self
                let isSelected = selectedAddressees.contains { element in
                    if ((element as! Addressee).cert == (foundAddressees[row] as! Addressee).cert) {
                        return true
                    }
                    return false
                }
                let isAddButtonDisabled = selectedIndexes.contains(row) || isSelected
                cell.populate(addressee: foundAddressees[row] as! Addressee, index: row, isAddButtonDisabled: isAddButtonDisabled)
                return cell
            case .addressees:
                let cell = tableView.dequeueReusableCell(withType: ContainerAddresseeCell.self, for: indexPath)!
                cell.delegate = self
                cell.populate(
                    addressee: selectedAddressees[row] as! Addressee,
                    index: row,
                    showRemoveButton: true)
                return cell
        }
    }
    
}
extension AddresseeViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .notifications:
            break
        case .search:
            break
        case .searchResult:
            break
        case .addressees:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section]
        switch section {
            case .addressees:
                if selectedAddressees.count > 0 {
                    var title: String!
                    title = sectionHeaderTitle[section]
                    
                    if let header = MoppApp.instance.nibs[.containerElements]?.instantiate(withOwner: self, type: ContainerTableViewHeaderView.self) {
                        
                        header.delegate = self
                        header.populate(
                            withTitle: title,
                            showAddButton: false)
                        return header
                    }
                }
                break
            default:
                break
            
        }
        return nil
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        let section = sections[_section]
        switch section {
            case .addressees:
                if selectedAddressees.count > 0 {
                    return ContainerTableViewHeaderView.height
                } else {
                    return 0
            }
            default:
                break
        }
        return 0
    }
    
}

extension AddresseeViewController : ContainerTableViewHeaderDelegate {
    func didTapContainerHeaderButton() {
        NotificationCenter.default.post(
            name: .startImportingFilesWithDocumentPickerNotificationName,
            object: nil,
            userInfo: [kKeyFileImportIntent: MoppApp.FileImportIntent.addToContainer, kKeyContainerType: LandingViewController.shared.containerType])
    }
}

extension AddresseeViewController : ContainerAddresseeCellDelegate {
    func removeAddressee(index: Int) {
        let previouslySelectedAddresseesCount = selectedAddressees.count - selectedIndexes.count
        
        if previouslySelectedAddresseesCount > 0 {
            // Checking if selected addressee is in foundAddressee
            let indexCount = selectedAddressees.count - previouslySelectedAddresseesCount - index - 1
            if indexCount > -1 {
                selectedIndexes.removeObject(at: indexCount)
            }
        } else {
            let indexCount = selectedAddressees.count - index - 1
            selectedIndexes.removeObject(at: indexCount)
        }
        
        selectedAddressees.removeObject(at: index)
        self.tableView.reloadData()
    }
    
    
}

extension AddresseeViewController : LandingViewControllerTabButtonsDelegate {
    func landingViewControllerTabButtonTapped(tabButtonId: LandingViewController.TabButtonId, sender: UIView) {
        addresseeViewControllerDelegate?.addAddresseeToContainer(selectedAddressees: selectedAddressees)
    }
}

extension AddresseeViewController : ContainerFoundAddresseeCellDelegate {
    func addAddresseeToSelectedArea(index: Int) {
        selectedIndexes.add(index)
        selectedAddressees.insert(foundAddressees[index], at: 0)
        self.tableView.reloadData()
    }
    
    

}

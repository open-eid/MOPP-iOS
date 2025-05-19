//
//  AddresseeViewController.swift
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

protocol AddresseeViewControllerDelegate: AnyObject {
    func addAddresseeToContainer(selectedAddressees: [Addressee])
}

class AddresseeViewController : MoppViewController {
    weak var addresseeViewControllerDelegate: AddresseeViewControllerDelegate? = nil
    @IBOutlet weak var tableView: UITableView!
    
    var submittedQuery = ""
    let defaultSectionFooterHeight = CGFloat(56)
    
    enum Section {
        case notifications
        case search
        case searchResult
        case addressees
        case addAll
    }
    
    var foundAddressees = [Addressee]()
    var selectedAddressees = [Addressee]()
    var notifications: [(isSuccess: Bool, text: String)] = []
    var selectedIndexes: NSMutableArray = []
    
    var sectionHeaderTitle: [Section: String] = [
        .addressees  : L(LocKey.containerHeaderCreateAddresseesTitle),
    ]
    
    internal static let sectionsDefault  : [Section] = [.notifications, .search, .searchResult, .addressees, .addAll]
    
    var sections: [Section] = AddresseeViewController.sectionsDefault
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationItemForPushedViewController(title: L(.containerAddresseeTitle))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dismissKeyboard()
        LandingViewController.shared.tabButtonsDelegate = self
        LandingViewController.shared.presentButtons([])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if selectedAddressees.count == 0 {
            UIAccessibility.post(notification: .screenChanged, argument: L(.cryptoRecipientAddingCancelled))
        }
    }
    
    private func dismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }

    deinit {
        printLog("Deinit AddreseeViewController")
    }
    
    private func searchLdap(textField: UITextField) {
        guard let text = textField.text else { return }
        let trimmedText = text.trimWhitespacesAndNewlines()
        textField.text = trimmedText
        submittedQuery = trimmedText
        selectedIndexes = []
        showLoading(show: true)

        guard MoppLibManager.shared.isConnected else {
            self.infoAlert(message: L(.noConnectionMessage))
            self.showLoading(show: false)
            return
        }

        Task(priority: .userInitiated) { [weak self] in

            let result = OpenLdap.search(identityCode: trimmedText)
            guard let self = self else { return }

            await MainActor.run {
                self.showLoading(show: false)

                guard !result.addressees.isEmpty else {
                    self.infoAlert(message: "\(L(.cryptoEmptyLdapLabel))")
                    return
                }

                if result.totalAddressees >= 50 {
                    self.infoAlert(message: "\(L(.cryptoTooManyResultsLdapLabel))")
                }

                self.foundAddressees = result.0.sorted { $0.identifier < $1.identifier }

                self.tableView.reloadData()
            }
        }
    }
}

extension AddresseeViewController : UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let searchField = textField as? SearchField
        searchField?.onSearchIconTapped = {
            guard let searchTextField = searchField else { return }
            guard let text = searchTextField.text else { return }
            if !text.isEmpty && !self.isSameQuery(text: text, submittedQuery: self.submittedQuery) {
                self.searchLdap(textField: searchTextField)
            }
        }
        
        searchField?.onClearButtonTapped = {
            guard let searchTextField = searchField else { return }
            searchTextField.text = ""
            self.removeSearchResults(textField: searchTextField)
        }
        
        return true
    }
    
    func removeEditingTarget(_ textField: UITextField) {
        textField.removeTarget(self, action: nil, for: .editingChanged)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        if string.isEmpty && (text.count <= 1) {
            textField.text = ""
            removeSearchResults(textField: textField)
        }
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        removeEditingTarget(textField)
        removeSearchResults(textField: textField)
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        removeEditingTarget(textField)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return false }
        if text.isEmpty || (text.isNumeric && text.count >= 11 &&
            !PersonalCodeValidator.isPersonalCodeValid(personalCode: text)) {
            let invalidPersonalCodeError = AlertUtil.errorDialog(errorMessage: L(.cryptoInvalidPersonalCodeTitle), topViewController: getTopViewController())
            self.present(invalidPersonalCodeError, animated: true)
        } else if !text.isEmpty && !isSameQuery(text: text, submittedQuery: submittedQuery) {
            searchLdap(textField: textField)
        }
        return true
    }
    
    func isSameQuery(text: String, submittedQuery: String) -> Bool {
        return text.trimWhitespacesAndNewlines() == self.submittedQuery
    }
    
    func removeSearchResults(textField: UITextField) {
        foundAddressees = []
        self.submittedQuery = ""
        tableView.beginUpdates()
        for (index, section) in sections.enumerated() {
            if section != .search {
                tableView.reloadSections(IndexSet(integer: index), with: .automatic)
            }
        }
        tableView.endUpdates()
        
        DispatchQueue.main.async {
            textField.becomeFirstResponder()
        }
    }
}


extension AddresseeViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tableView.rowHeight = UITableView.automaticDimension
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
            case .notifications:
                return notifications.count
            case .search:
                return 1
            case .searchResult:
                let foundAddresseesCount = foundAddressees.count
                if foundAddresseesCount == 1 {
                    UIAccessibility.post(notification: .screenChanged, argument: L(.cryptoRecipientFound))
                } else if foundAddresseesCount > 1 {
                    UIAccessibility.post(notification: .screenChanged, argument: L(.cryptoRecipientsFound, [String(foundAddresseesCount)]))
                }
                return foundAddresseesCount
            case .addressees:
                return selectedAddressees.count
        case .addAll:
            return 1
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
                cell.searchBar.delegate = self
                cell.accessibilityUserInputLabels = [""]
                
                if foundAddressees.isEmpty {
                    cell.placeholder.isHidden = false
                } else {
                    cell.placeholder.isHidden = true
                }
            
                return cell
            case .searchResult:
                let cell = tableView.dequeueReusableCell(withType: ContainerFoundAddresseeCell.self, for: indexPath)!
                cell.delegate = self
                if !UIAccessibility.isVoiceOverRunning {
                    cell.accessibilityLabel = ""
                    cell.accessibilityUserInputLabels = [""]
                }
                let isSelected = selectedAddressees.contains { element in
                    if ((element as Addressee).cert == (foundAddressees[row] as Addressee).cert) {
                        return true
                    }
                    return false
                }
                let isAddButtonDisabled = selectedIndexes.contains(row) || isSelected
                cell.populate(addressee: foundAddressees[row] as Addressee, index: row, isAddButtonDisabled: isAddButtonDisabled)
                if indexPath.row == 0 {
                    UIAccessibility.post(notification: .layoutChanged, argument: cell)
                }
                return cell
            case .addressees:
                let cell = tableView.dequeueReusableCell(withType: ContainerAddresseeCell.self, for: indexPath)!
                cell.delegate = self
                cell.populate(
                    addressee: selectedAddressees[row] as Addressee,
                    index: row,
                    showRemoveButton: true)
                cell.accessibilityUserInputLabels = [""]
            
                setConfirmButton(addresses: selectedAddressees)
                return cell
            case .addAll:
                let cell = tableView.dequeueReusableCell(withType: ContainerAddAllButtonCell.self, for: indexPath)!
                cell.delegate = self
                cell.populate(foundAddressees: self.foundAddressees, selectedAddresses: self.selectedAddressees)
                cell.accessibilityUserInputLabels = [""]
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
        case .addAll:
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
                    return UITableView.automaticDimension
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
        guard let landingViewControllerContainerType = LandingViewController.shared.containerType else {
            printLog("Unable to get LandingViewControlelr container type")
            return
        }
        NotificationCenter.default.post(
            name: .startImportingFilesWithDocumentPickerNotificationName,
            object: nil,
            userInfo: [kKeyFileImportIntent: MoppApp.FileImportIntent.addToContainer, kKeyContainerType: landingViewControllerContainerType])
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
        
        selectedAddressees.remove(at: index)

        setConfirmButton(addresses: selectedAddressees)

        self.tableView.reloadData()
    }
    
    
}

extension AddresseeViewController : LandingViewControllerTabButtonsDelegate {
    func landingViewControllerTabButtonTapped(tabButtonId: LandingViewController.TabButtonId, sender: UIView, containerType: MoppApp.ContainerType) {
        addresseeViewControllerDelegate?.addAddresseeToContainer(selectedAddressees: selectedAddressees)
    }
    
    func changeContainer(tabButtonId: LandingViewController.TabButtonId, containerType: MoppApp.ContainerType) {}
}

extension AddresseeViewController : ContainerFoundAddresseeCellDelegate {
    func addAddresseeToSelectedArea(index: Int, completionHandler: @escaping () -> Void) {

        selectedIndexes.add(index)
        
        let foundAddress = foundAddressees[index]
        if !selectedAddressees.contains(foundAddress) {
            selectedAddressees.insert(foundAddress, at: 0)
        }
        self.tableView.reloadData()
        
        setConfirmButton(addresses: selectedAddressees)
        completionHandler()
    }
    
    func addAddresseeToSelectedArea(addressee: Addressee) {
        if !selectedAddressees.contains(where: {(
            ($0.givenName != nil && $0.givenName == addressee.givenName &&
              $0.surname != nil && $0.surname == addressee.surname) ||
              $0.identifier == addressee.identifier) && $0.cert == addressee.cert && $0.validTo == addressee.validTo
        }) {
            selectedAddressees.insert(addressee, at: 0)
        }
        
        self.tableView.reloadData()
    }
    
    func addAllAddresseesToSelectedArea(addressees: [Addressee]) {
        for addressee in addressees {
            addAddresseeToSelectedArea(addressee: addressee)
        }
    }
    
    func setConfirmButton(addresses: [Addressee]) {
        if !addresses.isEmpty {
            LandingViewController.shared.presentButtons([.confirmButton])
        } else {
            LandingViewController.shared.presentButtons([])
        }
    }
}

//
//  SigningCategoryViewController.swift
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

import UIKit

class SigningCategoryViewController: MoppViewController {
    private(set) var timestampUrl: String!
    @IBOutlet weak var tableView: UITableView!
    
    var isDefaultTimestampValue = true
    var settingsTsaCertCell: SettingsTSACertCell?
    var settingsUseDefaultCell: SettingsDefaultValueCell?
    
    var currentlyEditingCell: IndexPath?
    
    var tableViewCells = [IndexPath: UITableViewCell]()
    
    enum Section {
        case header
        case fields
    }
    
    enum FieldId {
        case roleAndAddress
        case rpuuid
        case timestampUrl
        case useDefault
        case tsaCert
        case sivaCert
        case proxy
    }
    
    struct Field {
        enum Kind {
            case roleAndAddress
            case inputField
            case choice
            case timestamp
            case defaultSwitch
            case tsaCert
            case sivaCert
            case proxy
        }
        
        let id: FieldId
        let kind: Kind
        let title: String
        let placeholderText: NSAttributedString
        let value: String
        
        init(id: FieldId, kind: Kind, title: String, placeholderText: NSAttributedString, value: String) {
            self.id = id
            self.kind = kind
            self.title = title
            self.placeholderText = placeholderText
            self.value = value
        }
    }
    
    var sections:[Section] = [.header, .fields]
    
    var fields: [Field] = [
        Field(id: .roleAndAddress,
              kind: .roleAndAddress,
              title: L(.roleAndAddressRoleTitle),
              placeholderText: NSAttributedString(string: L(.roleAndAddressRoleTitle)),
              value: ""),
        Field(
            id: .rpuuid,
            kind: .inputField,
            title: L(.settingsRpUuidTitle),
            placeholderText: NSAttributedString(string: L(.settingsRpUuidPlaceholder), attributes: [NSAttributedString.Key.foregroundColor: UIColor.moppPlaceholderDarker]),
            value: DefaultsHelper.rpUuid
        ),
        Field(
            id: .timestampUrl,
            kind: .timestamp,
            title: L(.settingsTimestampUrlTitle),
            placeholderText: NSAttributedString(string: L(.settingsTimestampUrlPlaceholder), attributes: [NSAttributedString.Key.foregroundColor: UIColor.moppText]),
            value: DefaultsHelper.timestampUrl ?? MoppConfiguration.tsaUrl!
        ),
        Field(
            id: .useDefault,
            kind: .defaultSwitch,
            title: L(.settingsTimestampUseDefaultTitle),
            placeholderText: NSAttributedString(string: L(.settingsTimestampUseDefaultTitle)),
            value: ""),
        Field(
            id: .tsaCert,
            kind: .tsaCert,
            title: L(.settingsTimestampCertTitle),
            placeholderText: NSAttributedString(string: L(.settingsTimestampCertTitle)),
            value: ""),
        Field(
            id: .sivaCert,
            kind: .sivaCert,
            title: L(.settingsSivaServiceTitle),
            placeholderText: NSAttributedString(string: L(.settingsSivaServiceTitle)),
            value: ""),
        Field(
            id: .proxy,
            kind: .proxy,
            title: L(.settingsProxyTitle),
            placeholderText: NSAttributedString(string: L(.settingsProxyTitle)),
            value: "")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timestampUrl = DefaultsHelper.timestampUrl
        isDefaultTimestampValue = DefaultsHelper.defaultSettingsSwitch
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(accessibilityElementFocused(_:)), name: UIAccessibility.elementFocusedNotification, object: nil)

        if UIAccessibility.isVoiceOverRunning {
            DispatchQueue.main.async {
                self.view.accessibilityElements = [self.getAccessibilityElementsOrder()]
                self.tableView.reloadData()
            }
        }
    }
    
    @objc func accessibilityElementFocused(_ notification: Notification) {
        let topViewController = getTopViewController()
        if topViewController is SivaCertViewController || topViewController is ProxyViewController { return }
        if let element = notification.userInfo?[UIAccessibility.focusedElementUserInfoKey] as? UIView {
            let elementRect = element.convert(element.bounds, to: tableView)
            let offsetY = elementRect.midY - (tableView.frame.size.height / 4)
            tableView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
        }
    }
    
    override func keyboardWillShow(notification: NSNotification) {
        if !(getTopViewController() is SivaCertViewController) {
            let firstCell = tableView.cellForRow(at: currentlyEditingCell ?? IndexPath(row: 1, section: 1))
            tableView.setContentOffset(CGPoint(x: 0, y: (firstCell?.frame.origin.y ?? 0) - 100), animated: false)
        }
    }
    
    override func keyboardWillHide(notification: NSNotification) {
        if !(getTopViewController() is SivaCertViewController) {
            tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
    }
    
    func getAccessibilityElementsOrder() -> [Any] {
        let isDefaultTimestampSettingsEnabled = DefaultsHelper.defaultSettingsSwitch
        
        var accessibilityElementsOrder = [Any]()
        
        if !isDefaultTimestampSettingsEnabled {
            
            let classOrder = [SettingsDefaultValueCell.self, SettingsRoleAndAddressCell.self, SettingsFieldCell.self, SettingsTimeStampCell.self, SettingsTSACertCell.self, SivaCategoryCell.self, ProxyCategoryCell.self, SettingsHeaderCell.self,  SettingsDefaultValueCell.self]
            
            for className in classOrder {
                for key in tableViewCells.keys.sorted() {
                    if let cell = tableViewCells[key], type(of: cell) == className {
                        if cell.accessibilityElements != nil {
                            accessibilityElementsOrder.append(cell.accessibilityElements ?? [])
                        }
                    }
                }
            }
        } else {
            let accessibilityClassOrder = [SettingsDefaultValueCell.self, SettingsRoleAndAddressCell.self, SettingsFieldCell.self, SettingsTimeStampCell.self, SivaCategoryCell.self, ProxyCategoryCell.self, SettingsHeaderCell.self, SettingsDefaultValueCell.self]
            
            for className in accessibilityClassOrder {
                for key in tableViewCells.keys.sorted() {
                    if let cell = tableViewCells[key], type(of: cell) == className {
                        if cell.accessibilityElements != nil {
                            accessibilityElementsOrder.append(cell.accessibilityElements ?? [])
                        }
                    }
                }
            }
        }
        
        return accessibilityElementsOrder
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIAccessibility.elementFocusedNotification, object: nil)
    }
}

extension SigningCategoryViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section_: Int) -> Int {
        switch sections[section_] {
        case .header:
            return 1
        case .fields:
            return fields.count
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tableView.estimatedRowHeight = 44
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .header:
            let headerCell = tableView.dequeueReusableCell(withType: SettingsHeaderCell.self, for: indexPath)!
                headerCell.delegate = self
                headerCell.populate(with:L(.containerSignTitle))
                tableViewCells[indexPath] = headerCell
            return headerCell
        case .fields:
            let field = fields[indexPath.row]
            if isDefaultTimestampValue && field.kind == .tsaCert {
                break
            }
            switch field.kind {
            case .roleAndAddress:
                let roleAndAddressCell = tableView.dequeueReusableCell(withType: SettingsRoleAndAddressCell.self, for: indexPath)!
                roleAndAddressCell.populate(with: field)
                tableViewCells[indexPath] = roleAndAddressCell
                return roleAndAddressCell
            case .inputField:
                let fieldCell = tableView.dequeueReusableCell(withType: SettingsFieldCell.self, for: indexPath)!
                    fieldCell.delegate = self
                    fieldCell.populate(with: field)
                    tableViewCells[indexPath] = fieldCell
                switch field.id {
                case .rpuuid:
                    fieldCell.textField.isSecureTextEntry = true
                    fieldCell.textField.keyboardType = .default
                    break
                default: break
                }
                return fieldCell
            case .timestamp:
                let timeStampCell = tableView.dequeueReusableCell(withType: SettingsTimeStampCell.self, for: indexPath)!
                    timeStampCell.delegate = self
                    timeStampCell.populate(with: field)
                    tableViewCells[indexPath] = timeStampCell
                return timeStampCell
            case .choice:
                let choiceCell = tableView.dequeueReusableCell(withType: SettingsChoiceCell.self, for: indexPath)!
                    choiceCell.populate(with: field)
                    tableViewCells[indexPath] = choiceCell
                return choiceCell
            case .defaultSwitch:
                let useDefaultCell = tableView.dequeueReusableCell(withType: SettingsDefaultValueCell.self, for: indexPath)!
                    useDefaultCell.delegate = self
                    useDefaultCell.populate()
                    tableViewCells[indexPath] = useDefaultCell
                return useDefaultCell
            case .tsaCert:
                let tsaCertCell = tableView.dequeueReusableCell(withType: SettingsTSACertCell.self, for: indexPath)!
                    tsaCertCell.topViewController = getTopViewController()
                    tsaCertCell.populate()
                    tableViewCells[indexPath] = tsaCertCell
                return tsaCertCell
            case .sivaCert:
                let sivaCertCell = tableView.dequeueReusableCell(withType: SivaCategoryCell.self, for: indexPath)!
                sivaCertCell.topViewController = getTopViewController()
                sivaCertCell.populate()
                tableViewCells[indexPath] = sivaCertCell
                return sivaCertCell
            case .proxy:
                let proxyCell = tableView.dequeueReusableCell(withType: ProxyCategoryCell.self, for: indexPath)!
                proxyCell.topViewController = getTopViewController()
                proxyCell.populate()
                tableViewCells[indexPath] = proxyCell
                return proxyCell
            }
        }
        return UITableViewCell()
    }
    
    @objc func editingChanged(sender: UITextField) {
        let text = sender.text ?? String()
        if (text.count > 11) {
            sender.deleteBackward()
        }
    }
}

extension SigningCategoryViewController: SettingsHeaderCellDelegate {
    func didDismissSettings() {
        dismiss(animated: true, completion: nil)
    }
}

extension SigningCategoryViewController: SettingsCellDelegate {
    func didStartEditingField(_ field: FieldId, _ textField: UITextField) {
        return
    }
    
    func didStartEditingField(_ field: FieldId, _ indexPath: IndexPath) {
        switch field {
        case .rpuuid:
            currentlyEditingCell = indexPath
            break
        default:
            break
        }
    }
    
    func didEndEditingField(_ fieldId: SigningCategoryViewController.FieldId, with value: String) {
        switch fieldId {
        case .rpuuid:
            DefaultsHelper.rpUuid = value
            break
        default:
            break
        }
        currentlyEditingCell = nil
        UIAccessibility.post(notification: .screenChanged, argument: L(.settingsValueChanged))
    }
}

extension SigningCategoryViewController: SettingsTimeStampCellDelegate {
    func didChangeTimestamp(_ fieldId: SigningCategoryViewController.FieldId, with value: String?) {
        DefaultsHelper.timestampUrl = value
        MoppLibContainerActions.setup(success: {
            printLog("success")
        }, andFailure: { [weak self] error in
            let nsError = error as? NSError
            
            self?.errorAlertWithLink(message: MessageUtil.generateDetailedErrorMessage(error: nsError) ?? L(.genericErrorMessage))
        },
               withMoppConfiguration: MoppConfiguration.getMoppLibConfiguration(),
               andProxyConfiguration: ManualProxy.getMoppLibProxyConfiguration())
    }
}

extension SigningCategoryViewController: SettingsDefaultValueCellDelegate {
    func didChangeDefaultSwitch(_ field: FieldId, with switchValue: Bool?) {
        if let switchValue = switchValue {
            DefaultsHelper.defaultSettingsSwitch = switchValue
            isDefaultTimestampValue = switchValue
        }
        tableView.reloadData()
        
        if UIAccessibility.isVoiceOverRunning {
            DispatchQueue.main.async {
                self.view.accessibilityElements = self.getAccessibilityElementsOrder()
            }
        }
    }
}

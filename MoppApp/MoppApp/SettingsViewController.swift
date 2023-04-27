//
//  SettingsViewController.swift
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
class SettingsViewController: MoppViewController {
    private(set) var timestampUrl: String!
    @IBOutlet weak var tableView: UITableView!
    
    enum Section {
        case header
        case fields
    }
    
    enum FieldId {
        case rpuuid
        case timestampUrl
        case useDefault
    }
    
    struct Field {
        enum Kind {
            case inputField
            case choice
            case timestamp
            case defaultSwitch
        }
        
        let id: FieldId
        let kind: Kind
        let title: String
        let placeholderText: NSAttributedString
        let value: String
        
        init(id:FieldId, kind:Kind, title:String, placeholderText:NSAttributedString, value:String) {
            self.id = id
            self.kind = kind
            self.title = title
            self.placeholderText = placeholderText
            self.value = value
        }
    }
    
    var sections:[Section] = [.header, .fields]
    
    var fields:[Field] = [
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
            placeholderText: NSAttributedString(string: L(.settingsTimestampUrlPlaceholder), attributes: [NSAttributedString.Key.foregroundColor: UIColor.moppPlaceholderDarker]),
            value: DefaultsHelper.timestampUrl ?? MoppConfiguration.tsaUrl!
        ),
        Field(id: .useDefault, kind: .defaultSwitch, title: L(.settingsTimestampUseDefaultTitle), placeholderText: NSAttributedString(string: L(.settingsTimestampUseDefaultTitle)), value: "")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timestampUrl = DefaultsHelper.timestampUrl
    }

    
    override func viewDidAppear(_ animated: Bool) {
        self.view.accessibilityElements = getAccessibilityElementsOrder()
    }
    
    override func keyboardWillShow(notification: NSNotification) {
        let firstCell = tableView.cellForRow(at: IndexPath(row: 1, section: 1))
        tableView.setContentOffset(CGPoint(x: 0, y: (firstCell?.frame.origin.y ?? 0) - 100), animated: false)
    }
    
    override func keyboardWillHide(notification: NSNotification) {
        tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    func getAccessibilityElementsOrder() -> [Any] {
        var headerCellIndex: Int = 0
        var fieldCellIndex: Int = 0
        var timestampCellIndex: Int = 0
        var defaultValueCellIndex: Int = 0
        for (index, cell) in tableView.visibleCells.enumerated() {
            if cell is SettingsHeaderCell {
                headerCellIndex = index
            } else if cell is SettingsFieldCell {
                fieldCellIndex = index
            } else if cell is SettingsTimeStampCell {
                timestampCellIndex = index
            } else if cell is SettingsDefaultValueCell {
                defaultValueCellIndex = index
            }
        }
        
        guard let timestampCell = tableView.visibleCells[timestampCellIndex] as? SettingsTimeStampCell,
              let timestampTextfield = timestampCell.textField else {
            return []
        }
        
        guard let defaultValueCell = tableView.visibleCells[defaultValueCellIndex] as? SettingsDefaultValueCell,
              let timestampDefaultSwitch = defaultValueCell.useDefaultSwitch else {
            return []
        }
        
        guard let fieldCellAccessibilityElements = tableView.visibleCells[fieldCellIndex].accessibilityElements else {
            return []
        }
        
        guard let headerCellAccessibilityElements = tableView.visibleCells[headerCellIndex].accessibilityElements else {
            return []
        }
        
        return [
            timestampDefaultSwitch,
            fieldCellAccessibilityElements,
            timestampTextfield,
            headerCellAccessibilityElements,
            timestampDefaultSwitch,
        ]
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
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
                headerCell.populate(with:L(.settingsTitle))
            return headerCell
        case .fields:
            let field = fields[indexPath.row]
            switch field.kind {
            case .inputField:
                let fieldCell = tableView.dequeueReusableCell(withType: SettingsFieldCell.self, for: indexPath)!
                    fieldCell.delegate = self
                    fieldCell.populate(with: field)
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
                return timeStampCell
            case .choice:
                let choiceCell = tableView.dequeueReusableCell(withType: SettingsChoiceCell.self, for: indexPath)!
                    choiceCell.populate(with: field)
                return choiceCell
            case .defaultSwitch:
                let useDefaultCell = tableView.dequeueReusableCell(withType: SettingsDefaultValueCell.self, for: indexPath)!
                    useDefaultCell.delegate = self
                    useDefaultCell.populate()
                return useDefaultCell
            }
        }
    }
    
    @objc func editingChanged(sender: UITextField) {
        let text = sender.text ?? String()
        if (text.count > 11) {
            sender.deleteBackward()
        }
    }
}

extension SettingsViewController: SettingsHeaderCellDelegate {
    func didDismissSettings() {
        dismiss(animated: true, completion: nil)
    }
}

extension SettingsViewController: SettingsFieldCellDelegate {
    func didEndEditingField(_ fieldId: SettingsViewController.FieldId, with value:String) {
        switch fieldId {
        case .rpuuid:
            DefaultsHelper.rpUuid = value
            break
        default:
            break
        }
        UIAccessibility.post(notification: .screenChanged, argument: L(.settingsValueChanged))
    }
}

extension SettingsViewController: SettingsTimeStampCellDelegate {
    func didChangeTimestamp(_ fieldId: SettingsViewController.FieldId, with value: String?) {
        DefaultsHelper.timestampUrl = value

#if USE_TEST_DDS
        let useTestDDS = true
#else
        let useTestDDS = false
#endif
        MoppLibManager.sharedInstance()?.setup(success: {
            printLog("success")
        }, andFailure: { [weak self] error in
            let nsError = error as? NSError
            
            self?.errorAlert(message: MessageUtil.generateDetailedErrorMessage(error: nsError) ?? L(.genericErrorMessage), title: nsError?.userInfo["message"] as? String)
            }, usingTestDigiDocService: useTestDDS, andTSUrl: DefaultsHelper.timestampUrl ?? MoppConfiguration.getMoppLibConfiguration().tsaurl,
               withMoppConfiguration: MoppConfiguration.getMoppLibConfiguration())
    }
}

extension SettingsViewController: SettingsDefaultValueCellDelegate {
    func didChangeDefaultSwitch(_ field: FieldId, with switchValue: Bool?) {
        if let switchValue = switchValue {
            DefaultsHelper.defaultSettingsSwitch = switchValue
        }
        tableView.reloadData()
    }
    
    
}

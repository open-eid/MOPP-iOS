//
//  SettingsViewController.swift
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
class SettingsViewController: MoppViewController {
    private(set) var timestampUrl: String!
    @IBOutlet weak var tableView: UITableView!
    
    enum Section {
        case header
        case fields
    }
    
    enum FieldId {
        case missingId
        case phoneNumber
        case personalCode
        case timestampUrl
    }
    
    struct Field {
        enum Kind {
            case inputField
            case choice
            case groupSeparator
            case timestamp
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
            id: .phoneNumber,
            kind: .inputField,
            title: L(.settingsPhoneNumberTitle),
            placeholderText: NSMutableAttributedString(string: L(.settingsPhoneNumberPlaceholder), attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)]),
            value: DefaultsHelper.phoneNumber ?? String()
        ),
        Field(
            id: .personalCode,
            kind: .inputField,
            title: L(.settingsIdCodeTitle),
            placeholderText: NSAttributedString(string: L(.settingsIdCodePlaceholder), attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)]),
            value: DefaultsHelper.idCode
        ),
        Field(
            id: .missingId,
            kind: .groupSeparator,
            title: String(),
            placeholderText: NSAttributedString(string: String(), attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)]),
            value: String()
        ),
        Field(
            id: .timestampUrl,
            kind: .timestamp,
            title: L(.settingsTimestampUrlTitle),
            placeholderText: NSAttributedString(string: L(.settingsTimestampUrlPlaceholder), attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)]),
            value: DefaultsHelper.timestampUrl ?? MoppConfiguration.tsaUrl!
        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timestampUrl = DefaultsHelper.timestampUrl
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
    }
        
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension SettingsViewController: UITableViewDataSource {
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
                if (field.id == .personalCode) {
                    fieldCell.textField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
                }
                
                if (field.id == .phoneNumber) {
                    countryCodePrefill(textField: fieldCell.textField, countryCode: "372")
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
            case .groupSeparator:
                let groupSeparatorCell = tableView.dequeueReusableCell(withIdentifier: "SettingsGroupSeparator", for: indexPath)
                return groupSeparatorCell
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
        if fieldId == .phoneNumber {
            DefaultsHelper.phoneNumber = value
        }
        else if fieldId == .personalCode {
            DefaultsHelper.idCode = value
        }
    }
}

extension SettingsViewController: SettingsTimeStampCellDelegate {
    func didChangeTimestamp(_ fieldId: SettingsViewController.FieldId, with value: String?) {

#if USE_TEST_DDS
        let useTestDDS = true
#else
        let useTestDDS = false
#endif
        MoppLibManager.sharedInstance()?.setup(success: {
            MSLog("success")
        }, andFailure: { [weak self] error in
            let nsError = error! as NSError
            self?.errorAlert(message: L(.genericErrorMessage), title: nsError.userInfo["message"] as? String)
            }, usingTestDigiDocService: useTestDDS, andTSUrl: DefaultsHelper.timestampUrl ?? MoppConfiguration.getMoppLibConfiguration().tsaurl,
               withMoppConfiguration: MoppConfiguration.getMoppLibConfiguration())
    }
}

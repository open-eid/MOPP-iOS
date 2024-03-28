//
//  SettingsViewController.swift
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

class SettingsViewController: MoppViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func openSigningCategory(_ sender: ScaledButton) {
        openSigningCategoryView()
    }
    
    enum Section {
        case header
        case fields
    }
    
    enum FieldId {
        case signingCategory
        case resetSettings
    }
    
    struct Field {
        let id: FieldId
        let title: String
        
        init(id: FieldId, title: String) {
            self.id = id
            self.title = title
        }
    }
    
    var sections:[Section] = [.header, .fields]
    
    var fields:[Field] = [
        Field(
            id: .signingCategory,
            title: L(.containerSignTitle)
        ),
        Field(
            id: .resetSettings,
            title: L(.settingsResetButton)
        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    func resetSettings() {
        resetRPAndTimestamp()
        resetRoleAndAddress()
        resetTSA()
        resetSiva()
        resetProxy()
        
        tableView.reloadData()
    }

    func resetRPAndTimestamp() {
        DefaultsHelper.rpUuid = ""
        DefaultsHelper.timestampUrl = nil
        DefaultsHelper.defaultSettingsSwitch = true
    }

    func resetRoleAndAddress() {
        DefaultsHelper.isRoleAndAddressEnabled = false
        DefaultsHelper.roleNames = []
        DefaultsHelper.roleCity = ""
        DefaultsHelper.roleState = ""
        DefaultsHelper.roleCountry = ""
        DefaultsHelper.roleZip = ""
        
        CertUtil.removeCertificate(folder: SettingsTSACertCell.tsaFileFolder, fileName: DefaultsHelper.tsaCertFileName ?? "")
        
        CertUtil.removeCertificate(folder: SivaCertViewController.sivaFileFolder, fileName: DefaultsHelper.sivaCertFileName ?? "")
    }

    func resetTSA() {
        CertUtil.removeCertificate(folder: SettingsTSACertCell.tsaFileFolder, fileName: DefaultsHelper.tsaCertFileName ?? "")
        DefaultsHelper.tsaCertFileName = ""
    }

    func resetSiva() {
        CertUtil.removeCertificate(folder: SivaCertViewController.sivaFileFolder, fileName: DefaultsHelper.sivaCertFileName ?? "")
        DefaultsHelper.sivaCertFileName = ""
        DefaultsHelper.sivaAccessState = .defaultAccess
        DefaultsHelper.sivaUrl = Configuration.getConfiguration().SIVAURL
    }

    func resetProxy() {
        DefaultsHelper.proxySetting = .noProxy
        DefaultsHelper.proxyHost = ""
        DefaultsHelper.proxyPort = 80
        DefaultsHelper.proxyUsername = ""
        KeychainUtil.remove(key: proxyPasswordKey)
    }
    
    deinit {
        printLog("Deinit SettingsViewController")
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
            headerCell.populate(with: L(.settingsTitle))
            return headerCell
        case .fields:
            let field = fields[indexPath.row]
            switch field.id {
            case .signingCategory:
                let signingCategoryCell = tableView.dequeueReusableCell(withType: SigningCategoryCell.self, for: indexPath)!
                signingCategoryCell.populate(with: field.title)
                return signingCategoryCell
            case .resetSettings:
                let resetCell = tableView.dequeueReusableCell(withType: SettingsResetCell.self, for: indexPath)!
                resetCell.delegate = self
                resetCell.populate(with: field.title)
                return resetCell
            }
        }
    }
    
    @objc func editingChanged(sender: UITextField) {
        let text = sender.text ?? String()
        if (text.count > 11) {
            TextUtil.deleteBackward(textField: sender)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .header:
            break
        case .fields:
            let field = fields[indexPath.row]
            switch field.id {
            case .signingCategory:
                openSigningCategoryView()
                break
            case .resetSettings:
                resetSettings()
                break
            }
        }
    }
    
    private func openSigningCategoryView() {
        let signingCategoryViewController = UIStoryboard.settings.instantiateViewController(of: SigningCategoryViewController.self)
        signingCategoryViewController.modalPresentationStyle = .fullScreen
        present(signingCategoryViewController, animated: true)
    }
}

extension SettingsViewController: SettingsHeaderCellDelegate {
    func didDismissSettings() {
        dismiss(animated: true, completion: nil)
    }
}

extension SettingsViewController: SettingsResetCellDelegate {
    func didTapResetSettings() {
        resetSettings()
    }
}

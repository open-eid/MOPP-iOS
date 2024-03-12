//
//  SettingsDefaultValueCell.swift
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

protocol SettingsDefaultValueCellDelegate: AnyObject {
    func didChangeDefaultSwitch(_ field: SigningCategoryViewController.FieldId, with switchValue: Bool?)
}

class SettingsDefaultValueCell: UITableViewCell {

    @IBOutlet weak var useDefaultTitleLabel: UILabel!
    @IBOutlet weak var useDefaultSwitch: UISwitch!

    @IBAction func useDefaultToggled(_ sender: UISwitch) {
        delegate.didChangeDefaultSwitch(.useDefault, with: sender.isOn)
        updateUI()
    }

    weak var delegate: SettingsDefaultValueCellDelegate!
    
    override func awakeFromNib() {
        updateUI()

        useDefaultSwitch.accessibilityLabel = "\(useDefaultTitleLabel.text ?? L(.settingsTimestampUseDefaultTitle)) \(L(.settingsTimestampUrlTitle))"
        useDefaultSwitch.isUserInteractionEnabled = true
        useDefaultSwitch.isAccessibilityElement = true

        guard let useDefaultUISwitch = useDefaultSwitch else { return }
        accessibilityElements = [useDefaultUISwitch]
    }

    func populate() {
        updateUI()
    }

    func updateUI() {
        let useDefault = DefaultsHelper.rpUuid.isEmpty && DefaultsHelper.timestampUrl == nil
        useDefaultTitleLabel.isAccessibilityElement = false
        useDefaultSwitch.isOn = useDefault
        useDefaultTitleLabel.text = L(.settingsTimestampUseDefaultTitle)
        useDefaultSwitch.accessibilityLabel = "\(useDefaultTitleLabel.text ?? L(.settingsTimestampUseDefaultTitle)) \(L(.settingsTimestampUrlTitle))"
        if useDefaultSwitch.isOn {
            useDefaultSwitch.accessibilityLabel = L(.voiceControlDisableDefaultTimestampingService)
            useDefaultSwitch.accessibilityUserInputLabels = [L(.voiceControlDisableDefaultTimestampingService)]
        } else {
            useDefaultSwitch.accessibilityLabel = L(.voiceControlEnableDefaultTimestampingService)
            useDefaultSwitch.accessibilityUserInputLabels = [L(.voiceControlEnableDefaultTimestampingService)]
        }
        useDefaultSwitch.isUserInteractionEnabled = true
        useDefaultSwitch.isAccessibilityElement = true
    }
}

//
//  SettingsRoleAndAddressCell.swift
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

import Foundation

class SettingsRoleAndAddressCell: UITableViewCell {
    @IBOutlet weak var roleSwitchStackView: UIStackView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stateSwitch: UISwitch!
    
    @IBAction func stateToggled(_ sender: UISwitch) {
        if sender.isOff {
            DefaultsHelper.isRoleAndAddressEnabled = false
            stateSwitch.accessibilityUserInputLabels = [L(.voiceControlEnableRoleAndAddress)]
        } else {
            DefaultsHelper.isRoleAndAddressEnabled = true
            stateSwitch.accessibilityUserInputLabels = [L(.voiceControlDisableRoleAndAddress)]
        }
        updateUI()
    }
    
    var field: SigningCategoryViewController.Field!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateUI()
        
        guard let stateUISwitch = stateSwitch else { return }
        
        self.accessibilityElements = [stateUISwitch]
    }
    
    func populate(with field: SigningCategoryViewController.Field) {
        self.field = field
        updateUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateUI()
    }
    
    func updateUI() {
        roleSwitchStackView.isAccessibilityElement = false
        
        AccessibilityUtil.setAccessibilityElementsInStackView(stackView: roleSwitchStackView, isAccessibilityElement: true)

        titleLabel.text = L(.settingsRoleAndAddressTitle)
        titleLabel.isAccessibilityElement = false

        stateSwitch.isOn = DefaultsHelper.isRoleAndAddressEnabled
        stateSwitch.isAccessibilityElement = true
        stateSwitch.accessibilityLabel = titleLabel.text
        
        stateSwitch.accessibilityUserInputLabels = stateSwitch.isOn ? [L(.voiceControlDisableRoleAndAddress)] : [L(.voiceControlEnableRoleAndAddress)]
    }
}

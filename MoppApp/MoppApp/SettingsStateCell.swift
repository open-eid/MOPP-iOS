//
//  SettingsStateCell.swift
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

import Foundation

class SettingsStateCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stateSwitch: UISwitch!
    
    @IBAction func stateToggled(_ sender: UISwitch) {
        if sender.isOff {
            DefaultsHelper.isRoleAndAddressEnabled = false
        } else {
            DefaultsHelper.isRoleAndAddressEnabled = true
        }
        updateUI()
    }
    
    var field: SettingsViewController.Field!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func populate(with field: SettingsViewController.Field) {
        self.field = field
        updateUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateUI()
    }
    
    func updateUI() {
        stateSwitch.isOn = DefaultsHelper.isRoleAndAddressEnabled
        
        titleLabel.text = L(.settingsRoleAndAddressTitle)
    }
}

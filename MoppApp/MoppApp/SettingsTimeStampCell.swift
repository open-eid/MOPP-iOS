//
//  SettingsTimeStampCell.swift
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
import UIKit

protocol SettingsTimeStampCellDelegate: AnyObject {
    func didChangeTimestamp(_ field: SettingsViewController.FieldId, with value: String?)
}

class SettingsTimeStampCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!

    var field: SettingsViewController.Field!
    weak var delegate: SettingsTimeStampCellDelegate!

    override func awakeFromNib() {
        super.awakeFromNib()
        textField.moppPresentDismissButton()
        textField.layer.borderColor = UIColor.moppContentLine.cgColor
        textField.layer.borderWidth = 1
        textField.delegate = self

        guard let fieldUITextfield: UITextField = textField else {
            printLog("Unable to get textField")
            return
        }

        titleLabel.isAccessibilityElement = false
        textField.accessibilityLabel = L(.settingsTimestampUrlTitle)
        self.accessibilityElements = [fieldUITextfield]
    }

    func populate(with field:SettingsViewController.Field) {
        self.field = field
        updateUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateUI()
    }

    func updateUI() {
        let defaultSwitch = DefaultsHelper.defaultSettingsSwitch

        if defaultSwitch {
            textField.text = MoppConfiguration.tsaUrl
            delegate.didChangeTimestamp(field.id, with: nil)

        } else {
            textField.text = DefaultsHelper.timestampUrl ?? MoppConfiguration.tsaUrl
            delegate.didChangeTimestamp(field.id, with: DefaultsHelper.timestampUrl ?? MoppConfiguration.tsaUrl)
        }
        textField.isEnabled = !defaultSwitch
        textField.textColor = defaultSwitch ? UIColor.moppLabelDarker : UIColor.moppText
        textField.text = DefaultsHelper.timestampUrl ?? MoppConfiguration.tsaUrl

        titleLabel.text = L(.settingsTimestampUrlTitle)
        textField.placeholder = L(.settingsTimestampUrlPlaceholder)
        textField.layoutIfNeeded()
    }
}

extension SettingsTimeStampCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate.didChangeTimestamp(field.id, with: textField.text)
    }
}

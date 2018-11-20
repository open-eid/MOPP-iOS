//
//  SettingsTimeStampCell.swift
//  MoppApp
//
//  Created by Sander Hunt on 19/11/2018.
//  Copyright © 2018 Riigi Infosüsteemide Amet. All rights reserved.
//
import Foundation


protocol SettingsTimeStampCellDelegate: class {
    func didChangeTimestamp(_ field: SettingsViewController.FieldId, with value: String?)
}

class SettingsTimeStampCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var useDefaultSwitch: UISwitch!
    @IBOutlet weak var useDefaultTitleLabel: UILabel!
    
    var field: SettingsViewController.Field!
    weak var delegate: SettingsTimeStampCellDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.moppPresentDismissButton()
        textField.layer.borderColor = UIColor.moppContentLine.cgColor
        textField.layer.borderWidth = 1
        textField.delegate = self
    }
    
    func populate(with field:SettingsViewController.Field) {
        titleLabel.text = L(.settingsTimestampUrlTitle)
        textField.placeholder = L(.settingsTimestampUrlPlaceholder)
        textField.text = field.value
        useDefaultTitleLabel.text = L(.settingsTimestampUseDefaultTitle)
        self.field = field
        updateUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateUI()
    }
    
    func updateUI() {
        let useDefault = DefaultsHelper.timestampUrl == nil
        useDefaultSwitch.isOn = useDefault
        textField.isEnabled = !useDefault
        textField.textColor = useDefault ? UIColor.moppLabel : UIColor.moppText
        textField.layoutIfNeeded()
    }
    
    @IBAction func useDefaultToggled(_ sender: UISwitch) {
        if !sender.isOn {
            DefaultsHelper.timestampUrl = textField.text
        } else {
            textField.text = MoppLibManager.defaultTSUrl()
            DefaultsHelper.timestampUrl = nil
            delegate.didChangeTimestamp(field.id, with: DefaultsHelper.timestampUrl)
        }
        updateUI()
    }
}

extension SettingsTimeStampCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate.didChangeTimestamp(field.id, with: textField.text)
    }
}


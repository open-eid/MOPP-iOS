//
//  SettingsTimeStampCell.swift
//  MoppApp
//
//  Created by Sander Hunt on 19/11/2018.
//  Copyright © 2018 Riigi Infosüsteemide Amet. All rights reserved.
//
import Foundation
import UIKit


protocol SettingsTimeStampCellDelegate: AnyObject {
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
        titleLabel.font = UIFont.moppSmallRegular
        if isBoldTextEnabled() { titleLabel.font = UIFont.boldSystemFont(ofSize: titleLabel.font.pointSize) }
        textField.moppPresentDismissButton()
        textField.layer.borderColor = UIColor.moppContentLine.cgColor
        textField.layer.borderWidth = 1
        textField.delegate = self
        if isNonDefaultPreferredContentSizeCategory() {
            setCustomFont()
        }
        
        guard let fieldUITextfield: UITextField = textField, let useDefaultUISwitch: UISwitch = useDefaultSwitch else {
            printLog("Unable to get textField or useDefaultSwitch")
            return
        }
        
        titleLabel.isAccessibilityElement = false
        textField.accessibilityLabel = L(.settingsTimestampUrlTitle)
        useDefaultSwitch.accessibilityLabel = L(.settingsTimestampUseDefaultTitle)
        self.accessibilityElements = [fieldUITextfield, useDefaultUISwitch]
    }
    
    func setCustomFont() {
        titleLabel.font = UIFont.setCustomFont(font: .regular, nil, .body)
        textField.font = UIFont.setCustomFont(font: .regular, nil, .body)
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
        let useDefault = DefaultsHelper.timestampUrl == nil
        useDefaultSwitch.isOn = useDefault
        textField.isEnabled = !useDefault
        textField.textColor = useDefault ? UIColor.moppLabelDarker : UIColor.moppText
        textField.text = DefaultsHelper.timestampUrl ?? MoppConfiguration.tsaUrl
        if isBoldTextEnabled() { textField.font = UIFont.boldSystemFont(ofSize: textField.font?.pointSize ?? UIFont.moppMediumBold.pointSize) }
        
        titleLabel.text = L(.settingsTimestampUrlTitle)
        titleLabel.font = UIFont.moppMediumRegular
        if isBoldTextEnabled() { titleLabel.font = UIFont.boldSystemFont(ofSize: titleLabel.font.pointSize) }
        textField.placeholder = L(.settingsTimestampUrlPlaceholder)
        useDefaultTitleLabel.text = L(.settingsTimestampUseDefaultTitle)
        useDefaultTitleLabel.font = UIFont.setCustomFont(font: .regular, nil, .body)
        
        textField.layoutIfNeeded()
    }
    
    @IBAction func useDefaultToggled(_ sender: UISwitch) {
        if sender.isOff {
            DefaultsHelper.timestampUrl = textField.text
        } else {
            textField.text = MoppConfiguration.tsaUrl
            DefaultsHelper.timestampUrl = nil
            delegate.didChangeTimestamp(field.id, with: DefaultsHelper.timestampUrl)
        }
        updateUI()
    }
}

extension SettingsTimeStampCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        DefaultsHelper.timestampUrl = useDefaultSwitch.isOff ? textField.text : nil
        delegate.didChangeTimestamp(field.id, with: textField.text)
    }
}


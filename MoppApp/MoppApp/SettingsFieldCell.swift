//
//  SettingsFieldCell.swift
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

protocol SettingsCellDelegate: AnyObject {
    func didStartEditingField(_ field: SigningCategoryViewController.FieldId, _ indexPath: IndexPath)
    func didStartEditingField(_ field: SigningCategoryViewController.FieldId, _ textField: UITextField)
    func didEndEditingField(_ field: SigningCategoryViewController.FieldId, with value: String)
}

class SettingsFieldCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    var field: SigningCategoryViewController.Field!
    weak var delegate: SettingsCellDelegate!
    
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
        titleLabel.textColor = UIColor.moppText
        textField.accessibilityLabel = L(.settingsRpUuidTitle)
        textField.accessibilityUserInputLabels = [L(.voiceControlSigningService)]
        if UIAccessibility.isVoiceOverRunning {
            self.accessibilityElements = [fieldUITextfield]
        }
    }
    
    func populate(with field: SigningCategoryViewController.Field) {
        let defaultSwitch = DefaultsHelper.defaultSettingsSwitch
        if defaultSwitch {
            textField.text = nil
            DefaultsHelper.rpUuid = ""
        }
        titleLabel.text = field.title
        textField.isEnabled = !defaultSwitch
        let attributes = [
            NSAttributedString.Key.foregroundColor: UIColor.moppLabelDarker,
            NSAttributedString.Key.font : UIFont(name: "Roboto-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        ]
        textField.attributedPlaceholder = NSAttributedString(string: field.placeholderText.string, attributes: attributes)
        textField.text = !defaultSwitch ? DefaultsHelper.rpUuid : nil
        self.field = field
        
    }
}

extension SettingsFieldCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        var currentIndexPath = IndexPath(item: 1, section: 1)
        if let tableView = superview as? UITableView {
            if let indexPath = tableView.indexPath(for: self) {
                currentIndexPath = indexPath
            }
        }
        delegate.didStartEditingField(field.id, currentIndexPath)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate.didEndEditingField(field.id, with: textField.text ?? String())
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: textField)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.keyboardType == .default {
            return true;
        }
        if let text = textField.text as NSString? {
            let textAfterUpdate = text.replacingCharacters(in: range, with: string)
            return textAfterUpdate.isNumeric || textAfterUpdate.isEmpty
        }
        return true
    }
}

class SettingsTextField: ScaledTextField {
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 2
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        var newBounds = bounds
            newBounds.origin.x = 9
        return newBounds
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var newBounds = bounds
            newBounds.origin.x = 9
        return newBounds
    }
}

//
//  SettingsFieldCell.swift
//  MoppApp
//
/*
  * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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
protocol SettingsFieldCellDelegate: class {
    func didEndEditingField(_ field: SettingsViewController.FieldId, with value:String)
}

class SettingsFieldCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    var field: SettingsViewController.Field!
    weak var delegate: SettingsFieldCellDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.moppPresentDismissButton()
        textField.layer.borderColor = UIColor.moppContentLine.cgColor
        textField.layer.borderWidth = 1
        textField.delegate = self
    }
    
    func populate(with field:SettingsViewController.Field) {
        titleLabel.text = field.title
        textField.attributedPlaceholder = field.placeholderText
        textField.text = field.value
        self.field = field
    }
}

extension SettingsFieldCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate.didEndEditingField(field.id, with: textField.text ?? String())
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, textField)
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

class SettingsTextField: UITextField {
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

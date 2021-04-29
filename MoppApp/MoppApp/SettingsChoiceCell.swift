//
//  SettingsChoiceCell.swift
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
protocol SettingsChoiceCellDelegate: class {
    func didChooseOption(_ fieldId:SettingsViewController.FieldId, _ optionId: SettingsChoiceCell.OptionId?)
}

class SettingsChoiceCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var choiceView: SettingsChoiceView!
    
    weak var delegate: SettingsChoiceCellDelegate!
    var fieldId: SettingsViewController.FieldId!

    enum OptionId: Int {
        case containerTypeBdoc
        case containerTypeAsice
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        choiceView.delegate = self
        choiceView.layer.cornerRadius = 3
    }
    
    func populate(with field:SettingsViewController.Field) {
        self.fieldId = field.id
        titleLabel.text = field.title
        
        let optionBdoc = SettingsChoiceView.Option(title:"BDOC", tag: OptionId.containerTypeBdoc.rawValue)
        let optionAsice = SettingsChoiceView.Option(title:"ASIC-E", tag: OptionId.containerTypeAsice.rawValue)
        
        choiceView.options = [
            optionBdoc,
            optionAsice
        ]
        
        choiceView.update()
        
        if field.value == ContainerFormatBdoc {
            choiceView.updateButtons(with: optionBdoc)
        }
        else if field.value == ContainerFormatAsice {
            choiceView.updateButtons(with: optionAsice)
        }
        else {
            choiceView.updateButtons(with: optionBdoc)
        }
    }
}

extension SettingsChoiceCell: SettingsChoiceViewDelegate {
    func didChooseOption(_ option: SettingsChoiceView.Option) {
        delegate.didChooseOption(fieldId, SettingsChoiceCell.OptionId(rawValue: option.tag))
    }
}

//
//  SettingsChoiceView.swift
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
protocol SettingsChoiceViewDelegate: class {
    func didChooseOption(_ option: SettingsChoiceView.Option)
}

class SettingsChoiceView: UIView {
    @IBOutlet weak var stackView: UIStackView!
    
    weak var delegate: SettingsChoiceViewDelegate? = nil
   
    struct Option {
        var title: String
        var tag: Int
        
        init(title:String, tag:Int) {
            self.title = title
            self.tag = tag
        }
    }
   
    var options:[Option] = []
   
    override func awakeFromNib() {
       super.awakeFromNib()
       layer.borderColor = UIColor.moppBase.cgColor
       layer.borderWidth = 1
    }
    
    func update() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        options.forEach { option in
            let button = SettingsChoiceButton()
                button.setTitle(option.title)
                button.backgroundColor = UIColor.red
                button.option = option
                button.tapActionClosure = { [weak self] option in
                    self?.updateButtons(with: option)
                    self?.delegate?.didChooseOption(option)
                }
                button.populate()
            stackView.addArrangedSubview(button)
        }
    }
    
    func updateButtons(with option: SettingsChoiceView.Option) {
        stackView.arrangedSubviews.forEach { view in
            if let button = view as? SettingsChoiceButton {
                if button.option.title == option.title {
                    button.isSelected = true
                } else {
                    button.isSelected = false
                }
            }
        }
    }
}

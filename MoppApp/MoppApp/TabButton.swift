//
//  TabButton.swift
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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


class TabButton: UIView {
    enum Kind {
        case button
        case tab
    }
    
    @IBInspectable public var tab: Bool = true {
        didSet {
            kind = tab ? .tab : .button
        }
    }
    
    @IBInspectable public var localizationKey: String? = nil {
        didSet {
            if let localizationKey = localizationKey {
                let key = LocKey(rawValue: localizationKey)
                let str = L(key!)
                self.titleText = str
            }
        }
    }
    
    @IBInspectable public var unselectedColor: UIColor = UIColor.white
    @IBInspectable public var selectedColor: UIColor = UIColor.white
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var title: UILabel!
    var titleText: String = String()
    var kind: Kind = .button

    override func awakeFromNib() {
        super.awakeFromNib()
        
        title.text = titleText
    }

    func configure(kind: Kind) {
        self.kind = kind
    }
    
    func setSelected(_ selected: Bool) {
        button.isSelected = selected
        button.tintColor = selected ? selectedColor : unselectedColor
        title.textColor = selected ? selectedColor : unselectedColor
    }
}

//
//  ScaledLabel.swift
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

class ScaledLabel: UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scaleFont()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scaleFont()
    }
    
    func scaleFont() {
        self.isAccessibilityElement = true

        if UIAccessibility.isBoldTextEnabled {
            self.font = FontUtil.boldFont(font: self.font ?? UIFont(name: "Roboto-Bold", size: 16) ?? UIFont())
        } else {
            self.font = FontUtil.scaleFont(font: self.font ?? UIFont(name: "Roboto-Bold", size: 16) ?? UIFont())
        }
        
        self.adjustsFontForContentSizeCategory = true
        self.adjustsFontSizeToFitWidth = true
        self.minimumScaleFactor = 0.1
    }
    
    func resetLabelProperties() {
        self.adjustsFontForContentSizeCategory = false
        self.adjustsFontSizeToFitWidth = false
        self.minimumScaleFactor = 1
    }
    
    override func accessibilityElementDidBecomeFocused() {
        super.accessibilityElementDidBecomeFocused()
        NotificationCenter.default.post(name: .focusedAccessibilityElement, object: nil, userInfo: ["view": self])
        self.becomeFirstResponder()
    }
}

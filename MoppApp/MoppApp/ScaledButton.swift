//
//  ScaledButton.swift
//  MoppApp
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

class ScaledButton: UIButton {
    
    private static let defaultMaxFontSize = CGFloat(20)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        scaleButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scaleButton()
    }
    
    func scaleButton() {
        self.isAccessibilityElement = true

        if UIAccessibility.isBoldTextEnabled {
            self.titleLabel?.font = FontUtil.boldFont(font: self.titleLabel?.font ?? UIFont(name: "Roboto-Bold", size: 16) ?? UIFont())
        } else {
            self.titleLabel?.font = FontUtil.scaleFont(font: self.titleLabel?.font ?? UIFont())
        }

        self.titleLabel?.adjustsFontForContentSizeCategory = true
        self.titleLabel?.adjustsFontSizeToFitWidth = true
        self.titleLabel?.lineBreakMode = .byClipping
        self.titleLabel?.minimumScaleFactor = 0.1
        self.titleLabel?.numberOfLines = 1
        self.titleLabel?.textColor = UIColor.moppBase
        
        self.titleLabel?.sizeToFit()
        self.sizeToFit()
    }

    func resetButtonProperties() {
        self.titleLabel?.adjustsFontForContentSizeCategory = false
        self.titleLabel?.adjustsFontSizeToFitWidth = false
        self.titleLabel?.minimumScaleFactor = 1
        self.titleLabel?.numberOfLines = 0
        self.titleLabel?.sizeToFit()
        
        self.sizeToFit()
    }
    
    override func accessibilityElementDidBecomeFocused() {
        NotificationCenter.default.post(name: .hideKeyboardAccessibility, object: nil, userInfo: ["view": self])
        self.becomeFirstResponder()
    }
    
    func mediumFont() {
        self.titleLabel?.font = FontUtil.mediumFont(font: UIFont(name: "Roboto-Medium", size: 17) ?? UIFont())
    }
    
    func adjustedFont(_ maxFontSize: CGFloat = CGFloat(defaultMaxFontSize)) {
        if let buttonLabel = self.titleLabel {
            let originalFont = buttonLabel.font
            let scaledPointSize = UIFontMetrics.default.scaledValue(for: originalFont?.pointSize ?? CGFloat(maxFontSize))
            let maxPointSize = min(maxFontSize, scaledPointSize)
            let adjustedFont = originalFont?.withSize(maxPointSize)
            buttonLabel.font = adjustedFont
            
            self.titleLabel?.sizeToFit()
            self.sizeToFit()
        }
    }
}

//
//  ScaledTextView.swift
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

class ScaledTextView: UITextView {
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        scaleFont()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scaleFont()
    }
    
    func scaleFont() {
        if UIAccessibility.isBoldTextEnabled {
            self.font = FontUtil.boldFont(font: self.font ?? UIFont(name: "Roboto-Bold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16))
        } else {
            self.font = FontUtil.scaleFont(font: self.font ?? UIFont(name: "Roboto-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16))
        }
        
        setTextViewSize()
    }
    
    func setTextViewSize() {
        self.translatesAutoresizingMaskIntoConstraints = true
        self.sizeToFit()
        self.isScrollEnabled = false
    }
}

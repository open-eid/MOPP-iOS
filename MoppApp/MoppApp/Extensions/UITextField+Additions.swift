//
//  UITextField+Additions.swift
//  MoppApp
//
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
extension UITextField {

    func moppPresentDismissButton() {
    
        let toolbar = UIToolbar()
        toolbar.isAccessibilityElement = false
        toolbar.accessibilityLabel = ""
        toolbar.accessibilityValue = ""
    
        let doneButton = UIBarButtonItem(title: L(.doneButtonTitle), style: .done, target: self, action: #selector(__dismissKeyboard))
    
        let tap = UITapGestureRecognizer(target: self, action: nil)
        doneButton.customView?.addGestureRecognizer(tap)
        doneButton.isAccessibilityElement = true
        doneButton.accessibilityTraits = .button
        doneButton.accessibilityLabel = L(.doneButtonTitle)
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        toolbar.setItems([flexibleSpace, doneButton], animated: true)
        toolbar.sizeToFit()
        
        inputAccessoryView = toolbar
    }
    
    @objc func __dismissKeyboard() {
        resignFirstResponder()
    }
    
    func moveCursorToEnd() {
        if let cursorPosition = self.position(from: self.endOfDocument, offset: 0) {
            self.selectedTextRange = self.textRange(from: cursorPosition, to: cursorPosition)
        }
    }
}

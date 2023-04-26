//
//  MyeIDChangeCodesTextField.swift
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
class MyeIDChangeCodesTextField: ScaledTextField {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        moppPresentDismissButton()
        layer.borderWidth = 1
        layer.borderColor = UIColor.moppBackgroundLine.cgColor
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 15, y: bounds.origin.x, width: bounds.width, height: bounds.height)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 15, y: bounds.origin.x, width: bounds.width, height: bounds.height)
    }
}

//
//  SigningCategoryCell.swift
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

import UIKit

class SigningCategoryCell: UITableViewCell {
    
    @IBOutlet weak var signingCategoryButton: ScaledButton!
    
    func populate(with title: String) {
        signingCategoryButton.setTitle(title)
        signingCategoryButton.accessibilityLabel = title.lowercased()
        signingCategoryButton.accessibilityUserInputLabels = [L(.containerSignTitle)]
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guard let signingCategoryUIButton: ScaledButton = signingCategoryButton else {
            printLog("Unable to get signingCategoryButton")
            return
        }
        
        self.accessibilityElements = [signingCategoryUIButton]
    }
}

class EncryptingCategoryCell: UITableViewCell {

    @IBOutlet weak var encryptingCategoryButton: ScaledButton!

    func populate(with title: String) {
        encryptingCategoryButton.setTitle(title)
        encryptingCategoryButton.accessibilityLabel = title.lowercased()
        encryptingCategoryButton.accessibilityUserInputLabels = [L(.containerSignTitle)]
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        guard let encryptingCategoryUIButton: ScaledButton = encryptingCategoryButton else {
            printLog("Unable to get encryptingCategoryButton")
            return
        }

        self.accessibilityElements = [encryptingCategoryUIButton]
    }
}

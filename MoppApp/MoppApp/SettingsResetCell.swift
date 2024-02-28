//
//  SettingsResetCell.swift
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

import UIKit

protocol SettingsResetCellDelegate: AnyObject {
    func didTapResetSettings()
}

class SettingsResetCell: UITableViewCell {
    
    weak var delegate: SettingsResetCellDelegate!
    
    // Using UILabel, as UIButton does not scale well with bigger fonts
    @IBOutlet weak var resetSettingsButton: ScaledLabel!
    
    func populate(with title: String) {
        resetSettingsButton.isAccessibilityElement = true
        resetSettingsButton.text = title
        resetSettingsButton.accessibilityLabel = title.lowercased()
        resetSettingsButton.accessibilityUserInputLabels = [L(.voiceControlResetButton)]
        resetSettingsButton.font = .moppMedium
        resetSettingsButton.textColor = .systemBlue
        resetSettingsButton.isUserInteractionEnabled = true
        resetSettingsButton.resetLabelProperties()
        
        if resetSettingsButton.gestureRecognizers == nil || resetSettingsButton.gestureRecognizers?.isEmpty == true {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(resetSettingsButtonTapped))
            resetSettingsButton.addGestureRecognizer(tapGesture)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guard let resetSettingsUIButton: ScaledLabel = resetSettingsButton else {
            printLog("Unable to get resetSettingsButton")
            return
        }

        self.accessibilityElements = [resetSettingsUIButton]
    }
    
    @objc func resetSettingsButtonTapped() {
        delegate.didTapResetSettings()
    }
}

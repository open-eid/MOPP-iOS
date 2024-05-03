//
//  SivaCategoryCell.swift
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

class SivaCategoryCell: UITableViewCell {
    
    @IBOutlet weak var accessToSivaView: UIView!
    @IBOutlet weak var accessToSivaButton: ScaledLabel!
    
    @objc func openAccessToSivaSettings() {
        openAccessToSivaView()
    }
    
    weak var topViewController: UIViewController?
    
    override func awakeFromNib() {
        updateUI()
        
        guard let accessToSivaUIButton: ScaledLabel = accessToSivaButton else {
            printLog("Unable to get accessToSivaButton")
            return
        }
        
        if UIAccessibility.isVoiceOverRunning {
            self.accessibilityElements = [accessToSivaUIButton]
        }
    }
    
    func populate() {
        updateUI()
    }
    
    func updateUI() {
        if !(self.accessToSivaButton.gestureRecognizers?.contains(where: { $0 is UITapGestureRecognizer }) ?? false) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.openAccessToSivaSettings))
            self.accessToSivaButton.addGestureRecognizer(tapGesture)
            self.accessToSivaButton.isUserInteractionEnabled = true
        }
        
        self.accessToSivaButton.text = L(.settingsSivaServiceTitle)
        self.accessToSivaButton.accessibilityLabel = self.accessToSivaButton.text?.lowercased()
        self.accessToSivaButton.isUserInteractionEnabled = true
        self.accessToSivaButton.resetLabelProperties()
        
        self.accessToSivaView.accessibilityUserInputLabels = [L(.voiceControlSivaCategory)]
    }
    
    private func openAccessToSivaView() {
        let accessToSivaViewController = UIStoryboard.settings.instantiateViewController(of: SivaCertViewController.self)
        accessToSivaViewController.modalPresentationStyle = .custom
        accessToSivaViewController.modalTransitionStyle = .crossDissolve
        topViewController?.present(accessToSivaViewController, animated: true)
    }
}

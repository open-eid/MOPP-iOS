//
//  ProxyCategoryCell.swift
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

class ProxyCategoryCell: UITableViewCell {
    
    
    @IBOutlet weak var accessToProxySettings: ScaledButton!
    
    @IBAction func openAccessToProxySettings(_ sender: ScaledButton) {
        openAccessToProxyView()
    }
    
    weak var topViewController: UIViewController?
    
    override func awakeFromNib() {
        updateUI()
        
        guard let accessToProxyUISettings: ScaledButton = accessToProxySettings else {
            printLog("Unable to get accessToProxySettings")
            return
        }
        
        if UIAccessibility.isVoiceOverRunning {
            self.accessibilityElements = [accessToProxyUISettings]
        }
    }
    
    func populate() {
        updateUI()
    }
    
    func updateUI() {
        self.accessToProxySettings.setTitle(L(.settingsProxyTitle))
        self.accessToProxySettings.accessibilityLabel = self.accessToProxySettings.titleLabel?.text?.lowercased()
        self.accessToProxySettings.mediumFont()
    }
    
    private func openAccessToProxyView() {
        let accessToProxyViewController = UIStoryboard.settings.instantiateViewController(of: ProxyViewController.self)
        accessToProxyViewController.modalPresentationStyle = .custom
        accessToProxyViewController.modalTransitionStyle = .crossDissolve
        topViewController?.present(accessToProxyViewController, animated: true)
    }
}

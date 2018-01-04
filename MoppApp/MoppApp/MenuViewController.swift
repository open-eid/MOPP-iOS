//
//  MenuViewController.swift
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
import UIKit

class MenuViewController : MoppViewController {

    @IBOutlet weak var versionLabel     : UILabel!
    @IBOutlet weak var helpButton       : UIButton!
    @IBOutlet weak var introButton      : UIButton!
    @IBOutlet weak var documentsButton  : UIButton!
    @IBOutlet weak var settingsButton   : UIButton!
    @IBOutlet weak var aboutButton      : UIButton!

    @IBAction func dismissAction() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? String()
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? String()
        versionLabel.text = "Version \(version) - \(build)"
        
        helpButton      .setLocalizedTitle(.menuHelp)
        introButton     .setLocalizedTitle(.menuIntro)
        documentsButton .setLocalizedTitle(.menuFilemanager)
        settingsButton  .setLocalizedTitle(.menuSettings)
        aboutButton     .setLocalizedTitle(.menuAbout)
        
        lightContentStatusBarStyle = true
    
        let blurLayer = CALayer()
        if let filter = CIFilter(name: "CIGaussianBlur") {
            blurLayer.backgroundFilters = [filter]
            view.layer.addSublayer(blurLayer)
        }
        
        // Needed to dismiss this view controller in case of opening a container from outside the app
        NotificationCenter.default.addObserver(self, selector: #selector(receiveOpenContainerNotification), name: .openContainerNotificationName, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func receiveOpenContainerNotification() {
        dismiss(animated: true, completion: nil)
    }
}

//
//  MenuViewController.swift
//  MoppApp
//
//  Created by Sander Hunt on 19/11/2017.
//  Copyright © 2017 Riigi Infosüsteemide Amet. All rights reserved.
//

import Foundation
import UIKit

class MenuViewController : MoppViewController {

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
    }
}

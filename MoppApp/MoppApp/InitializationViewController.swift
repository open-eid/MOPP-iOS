//
//  InitializationViewController.swift
//  MoppApp
//
//  Created by Sander Hunt on 10/11/2017.
//  Copyright © 2017 Riigi Infosüsteemide Amet. All rights reserved.
//

import Foundation
import UIKit
import MoppLib


class InitializationViewController : UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let launchImageView = Bundle.main.loadNibNamed("LaunchScreen", owner: self, options: nil)?.last as? UIView
        view.addSubview(launchImageView!)
        launchImageView?.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MoppLibManager.sharedInstance().setup(success: {
            DispatchQueue.main.async {
                MoppApp.instance.setupTabController()
            }
        }, andFailure: { _ in
            DispatchQueue.main.async {
                MoppApp.instance.setupTabController()
            }
        })
    }

}

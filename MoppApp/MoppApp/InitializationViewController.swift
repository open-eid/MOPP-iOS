//
//  InitializationViewController.swift
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
import MoppLib


class InitializationViewController : UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let launchImageView = Bundle.main.loadNibNamed("LaunchScreen", owner: self, options: nil)?.last as? UIView {
            view.addSubview(launchImageView)
            launchImageView.translatesAutoresizingMaskIntoConstraints = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
#if USE_TEST_DDS
        let useTestDDS = true
#else
        let useTestDDS = false
#endif
        
        MoppLibManager.sharedInstance().setup(success: {
            DispatchQueue.main.async {
                MoppApp.instance.setupTabController()
            }
        },
        andFailure: { _ in
            DispatchQueue.main.async {
                MoppApp.instance.setupTabController()
            }
        },
        usingTestDigiDocService: useTestDDS
        )
    }

}

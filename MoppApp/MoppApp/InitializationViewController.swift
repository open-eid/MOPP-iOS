//
//  InitializationViewController.swift
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
import MoppLib

class InitializationViewController : UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MoppLibContainerActions.setup(success: {
            DispatchQueue.main.async {
                MoppApp.instance.setupTabController()
            }
        },
        andFailure: { _ in
            DispatchQueue.main.async {
                MoppApp.instance.setupTabController()
            }
        },
        andTSUrl: DefaultsHelper.timestampUrl ?? MoppConfiguration.getMoppLibConfiguration().tsaurl,
        withMoppConfiguration: MoppConfiguration.getMoppLibConfiguration(),
        andProxyConfiguration: ManualProxy.getMoppLibProxyConfiguration()
        )
    }

}

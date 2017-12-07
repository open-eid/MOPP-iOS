//
//  MoppViewController.swift
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


class MoppViewController : UIViewController {
    var lightContentStatusBarStyle : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: .willEnterForegroundNotificationName, object: self, queue: OperationQueue.main) { [weak self] _ in
            self?.willEnterForeground()
        }
        
        let titleImageView = UIImageView(image: UIImage(named: "Logo_Vaike"))
        navigationItem.titleView = titleImageView
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupStatusBarStyle()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        restoreStatusBarStyle()
    }
    
    fileprivate func setupStatusBarStyle() {
        MoppApp.instance.statusBarStyle = (lightContentStatusBarStyle ? .lightContent : .default)
    }
    
    fileprivate func restoreStatusBarStyle() {
        if let presentingVC = presentingViewController as? MoppViewController {
            presentingVC.setupStatusBarStyle()
        }
        else if let navController = navigationController
            , navController.viewControllers.count > 1
            , let prevVC = navController.viewControllers.last as? MoppViewController {
            
            prevVC.setupStatusBarStyle()
        }
        else {
            MoppApp.instance.statusBarStyle = .default
        }
    }
    
    func willEnterForeground() {
    
    }
    
    var spinnerView: SpinnerView? {
        get {
            return view.subviews.first(where: { $0 is SpinnerView }) as? SpinnerView
        }
    }
    
    func showLoading(show: Bool, forFrame: CGRect? = nil) {
        if show {
            if let spinnerView = spinnerView {
                spinnerView.show(true)
            } else {
                if let spinnerView = MoppApp.instance.nibs[.customElements]?.instantiate(withOwner: self, type: SpinnerView.self) {
                    spinnerView.show(true)
                    spinnerView.frame = forFrame ?? view.frame
                    view.addSubview(spinnerView)
                }
            }
        } else {
            if let spinnerView = spinnerView {
                spinnerView.show(false)
                spinnerView.removeFromSuperview()
            }
        }
    }
    
    func refreshLoadingAnimation() {
        if let spinnerView = view.subviews.first(where: { $0 is SpinnerView }) as? SpinnerView {
            spinnerView.show(true)
        }
    }
}

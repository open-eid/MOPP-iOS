//
//  MoppViewController.swift
//  MoppApp
//
//  Created by Sander Hunt on 19/11/2017.
//  Copyright © 2017 Riigi Infosüsteemide Amet. All rights reserved.
//

import Foundation
import UIKit


class MoppViewController : UIViewController {
    var lightContentStatusBarStyle : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleImageView = UIImageView(image: UIImage(named: "Logo_Vaike"))
        navigationItem.titleView = titleImageView
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
}

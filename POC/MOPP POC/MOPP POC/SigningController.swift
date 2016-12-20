//
//  SigningController.swift
//  MOPP POC
//
//  Created by Katrin Annuk on 19/12/16.
//  Copyright © 2016 Katrin Annuk. All rights reserved.
//

import UIKit

class SigningController: UIViewController {
    @IBOutlet weak var textField: UITextView!
    @IBOutlet weak var signatureField: UITextView!
    @IBOutlet weak var pinField: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signText(_ sender: Any) {
        
    }
}

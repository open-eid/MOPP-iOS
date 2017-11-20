//
//  MyeIDViewController.swift
//  MoppApp
//
//  Created by Sander Hunt on 20/11/2017.
//  Copyright © 2017 Riigi Infosüsteemide Amet. All rights reserved.
//

import Foundation


class MyeIDViewController : MoppViewController {

    @IBOutlet weak var beginLabel: UILabel!
    @IBOutlet weak var beginAltLabel: UILabel!
    @IBOutlet weak var beginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        beginLabel.text = L(LocKey.MyeidViewBeginLabel)
        beginAltLabel.text = L(LocKey.MyeidViewBeginAltLabel)
        beginButton.localizedTitle = LocKey.MyeidViewBeginButton
    }
}

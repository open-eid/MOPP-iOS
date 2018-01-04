//
//  SigningFileImportMissingCell.swift
//  MoppApp
//
//  Created by Sander Hunt on 03/01/2018.
//  Copyright © 2018 Riigi Infosüsteemide Amet. All rights reserved.
//

import Foundation


class SigningFileImportMissingCell : UITableViewCell {
    @IBOutlet weak var label: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        label.text = L(LocKey.signingMissingFileImportMessage)
    }
}

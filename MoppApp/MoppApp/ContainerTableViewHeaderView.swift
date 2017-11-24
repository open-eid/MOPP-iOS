//
//  ContainerTableViewHeaderView.swift
//  MoppApp
//
//  Created by Sander Hunt on 23/11/2017.
//  Copyright © 2017 Riigi Infosüsteemide Amet. All rights reserved.
//

import Foundation


class ContainerTableViewHeaderView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func populate(withTitle title: String, showAddButton: Bool) {
        addButton.isHidden = !showAddButton
        titleLabel.text = title
    }
}

//
//  ContainerAddresseeCell.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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

protocol ContainerAddresseeCellDelegate : class {
    func removeAddressee(index: Int)
}

class ContainerAddresseeCell: UITableViewCell, AddresseeActions {
    static let height: CGFloat = 58

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var bottomBorder: UIView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var removeButton: UIButton!
    weak var delegate: ContainerAddresseeCellDelegate!
    var removeIndex: Int = 0
    
    
    @IBAction func removeAddressee(_ sender: Any) {
        delegate.removeAddressee(index: removeIndex)
    }
    
    func populate(addressee: Addressee, index: Int, showRemoveButton: Bool) {
        removeButton.isHidden = !showRemoveButton
        removeButton.accessibilityLabel = L(.cryptoRemoveAddresseeButton)
        removeIndex = index
        nameLabel.text = determineName(addressee: addressee)
        infoLabel.text = determineInfo(addressee: addressee)
    }
}

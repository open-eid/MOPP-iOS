//
//  ContainerFoundAddresseeCell.swift
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

protocol ContainerFoundAddresseeCellDelegate : AnyObject {
    func addAddresseeToSelectedArea(index: Int)
}


class ContainerFoundAddresseeCell: UITableViewCell, AddresseeActions {
    
    static let height: CGFloat = 58
    
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var bottomBorderView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    weak var delegate: ContainerFoundAddresseeCellDelegate!
    var index: Int = 0
    
    @IBAction func addAddressee(_ sender: Any) {
        delegate.addAddresseeToSelectedArea(index: index)
        UIAccessibility.post(notification: .screenChanged, argument: L(.cryptoRecipientAdded))
    }
    
    func populate(addressee: Addressee, index: Int, isAddButtonDisabled: Bool) {
        self.index = index

        nameLabel.text = determineName(addressee: addressee)
        infoLabel.text = determineInfo(addressee: addressee)
        
        if isAddButtonDisabled {
            addButton.isEnabled = false
            addButton.setTitle(L(LocKey.cryptoAddresseeAddedButtonTitle))
            addButton.setTitleColor(UIColor.moppLabelDarker, for: .disabled)
        } else {
            addButton.isEnabled = true
            addButton.setTitle(L(LocKey.cryptoAddAddresseeButtonTitle))
            addButton.accessibilityLabel = L(.cryptoAddAddresseeButtonTitle).lowercased()
            addButton.tintColor = UIColor.moppBase
        }
        
    }
}

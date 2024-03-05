//
//  ContainerAddAllButtonCell.swift
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

import Foundation

class ContainerAddAllButtonCell: UITableViewCell {
    
    var addressees = [Addressee]()
    
    @IBOutlet weak var addAllButtonView: UIView!
    @IBOutlet weak var addAllButton: ScaledLabel!
    
    weak var delegate: ContainerFoundAddresseeCellDelegate!
    
    func populate(foundAddressees: [Addressee], selectedAddresses: [Addressee]) {
        
        self.addressees = []
        
        // Do not add duplicate addressees
        for addressee in foundAddressees {
            if !selectedAddresses.contains(addressee) {
                self.addressees.append(addressee)
            }
        }
        
        if !(self.addAllButton.gestureRecognizers?.contains(where: { $0 is UITapGestureRecognizer }) ?? false) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleAddAll(_:)))
            self.addAllButton.addGestureRecognizer(tapGesture)
            self.addAllButton.isUserInteractionEnabled = true
        }
        
        // Hide "Add all" button when there are no results at first
        guard !foundAddressees.isEmpty else {
            addAllButton.isHidden = true
            return
        }
        
        addAllButton.isHidden = false
        addAllButton.text = L(.cryptoAddresseeAddAllButton)
        addAllButton.backgroundColor = .clear
        addAllButton.accessibilityLabel = addAllButton.text?.lowercased()
        addAllButton.font = .moppMedium
        addAllButton.textColor = .systemBlue
        addAllButton.isUserInteractionEnabled = true
        addAllButton.resetLabelProperties()

        addAllButtonView.accessibilityUserInputLabels = [L(.cryptoAddresseeAddAllButton)]
    }
    
    @objc func handleAddAll(_ sender: UITapGestureRecognizer) {
        delegate.addAllAddresseesToSelectedArea(addressees: addressees)
        
        UIAccessibility.post(notification: .screenChanged, argument: L(.cryptoRecipientsAdded))
    }
}

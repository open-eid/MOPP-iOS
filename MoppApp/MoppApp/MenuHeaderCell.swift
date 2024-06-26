//
//  MenuHeaderCell.swift
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
protocol MenuHeaderDelegate: AnyObject {
    func menuHeaderDismiss()
}

class MenuHeaderCell : UITableViewCell {
    weak var delegate: MenuHeaderDelegate!
    
    @IBOutlet weak var menuCloseButton: UIButton!
    
    @IBAction func dismissAction() {
        delegate.menuHeaderDismiss()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        menuCloseButton.accessibilityLabel = L(.menuClose)
        menuCloseButton.accessibilityUserInputLabels = [L(.voiceControlClose)]
    }
}

//
//  ContainerNotificationCell.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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


class ContainerNotificationCell: UITableViewCell {
    static let height: CGFloat = 44
    @IBOutlet weak var infoLabel: ScaledLabel!
    @IBOutlet weak var linkLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func populate(isSuccess: Bool, text: String) {
        contentView.backgroundColor = isSuccess ? UIColor.moppGreen700 : UIColor.moppWarning
        infoLabel.text = text
        infoLabel.textColor = isSuccess ? .white : .black
    }
}

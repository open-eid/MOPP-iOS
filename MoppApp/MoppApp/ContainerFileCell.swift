//
//  ContainerFileCell.swift
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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


protocol ContainerFileDelegate: class {
    func removeDataFile(dataFileIndex: Int)
}

class ContainerFileCell: UITableViewCell {
    static let height: CGFloat = 44
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var bottomBorderView: UIView!
    @IBOutlet weak var removeButton: UIView!
    
    weak var delegate: ContainerFileDelegate? = nil
    var dataFileIndex: Int!
    
    @IBAction func removeAction() {
        delegate?.removeDataFile(dataFileIndex: dataFileIndex)
    }
    
    func populate(name: String, showBottomBorder: Bool, showRemoveButton: Bool, dataFileIndex: Int) {
        bottomBorderView.isHidden = !showBottomBorder
        filenameLabel.text = name
        removeButton.isHidden = !showRemoveButton
        self.dataFileIndex = dataFileIndex
    }
}

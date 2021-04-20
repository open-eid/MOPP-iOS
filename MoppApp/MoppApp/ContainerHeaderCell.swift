//
//  ContainerHeaderCell.swift
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

protocol ContainerHeaderDelegate: class {
    func editContainerName(completion: @escaping (_ fileName: String) -> Void)
}

class ContainerHeaderCell: UITableViewCell {
    static let height: CGFloat = 58
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var editContainerNameButton: UIButton!
    
    weak var delegate: ContainerHeaderDelegate? = nil
    
    @IBAction func editContainerName(_ sender: Any) {
        delegate?.editContainerName(completion: { (fileName: String) in
            guard !fileName.isEmpty else {
                NSLog("Filename is empty, container name not changed")
                return
            }
            DispatchQueue.main.async {
                self.filenameLabel.text = fileName
            }
        })
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.text = L(.containerHeaderTitle)
    }
    
    func populate(name: String, isEditButtonEnabled: Bool) {
        filenameLabel.text = name
        editContainerNameButton.isHidden = isEditButtonEnabled
        editContainerNameButton.accessibilityLabel = L(.containerEditNameButton)
    }
}

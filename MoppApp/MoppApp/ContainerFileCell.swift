//
//  ContainerFileCell.swift
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


protocol ContainerFileDelegate: class {
    func removeDataFile(dataFileIndex: Int)
    func saveDataFile(fileName: String?)
}

class ContainerFileCell: UITableViewCell {
    static let height: CGFloat = 44
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var bottomBorderView: UIView!
    @IBOutlet weak var removeButton: UIView!
    @IBOutlet weak var saveButton: UIButton!
    
    weak var delegate: ContainerFileDelegate? = nil
    var dataFileIndex: Int!
    
    @IBOutlet weak var openPreviewView: UIView!
    
    @IBAction func removeAction() {
        delegate?.removeDataFile(dataFileIndex: dataFileIndex)
    }
    
    @IBAction func saveAction(_ sender: Any) {
        delegate?.saveDataFile(fileName: filenameLabel.text ?? "-")
    }
    
    func populate(name: String, showBottomBorder: Bool, showRemoveButton: Bool, showDownloadButton: Bool, dataFileIndex: Int) {
        bottomBorderView.isHidden = !showBottomBorder
        filenameLabel.text = name
        removeButton.isHidden = !showRemoveButton
        removeButton.accessibilityLabel = formatString(text: L(.fileImportRemoveFile), additionalText: filenameLabel.text)
        saveButton.isHidden = !showDownloadButton
        saveButton.accessibilityLabel = formatString(text: L(.fileImportSaveFile), additionalText: filenameLabel.text)
        self.dataFileIndex = dataFileIndex
    }
}

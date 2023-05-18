//
//  ContainerFileCell.swift
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


protocol ContainerFileDelegate: AnyObject {
    func removeDataFile(dataFileIndex: Int)
    func saveDataFile(fileName: String?)
}

class ContainerFileCell: UITableViewCell {
    static let height: CGFloat = 44
    @IBOutlet weak var signingFileNameActionsStackView: UIStackView!
    @IBOutlet weak var cryptoFileNameActionsStackView: UIStackView!
    @IBOutlet weak var filenameLabel: ScaledLabel!
    @IBOutlet weak var bottomBorderView: UIView!
    @IBOutlet weak var signingActionsStackView: UIStackView!
    @IBOutlet weak var cryptoActionsStackView: UIStackView!
    @IBOutlet weak var removeButton: UIView!
    @IBOutlet weak var saveButton: UIButton!
    
    weak var delegate: ContainerFileDelegate? = nil
    var dataFileIndex: Int!
    
    @IBAction func removeAction() {
        delegate?.removeDataFile(dataFileIndex: dataFileIndex)
    }
    
    @IBAction func saveAction(_ sender: Any) {
        delegate?.saveDataFile(fileName: filenameLabel.text?.sanitize() ?? "-")
    }
    
    func populate(name: String, showBottomBorder: Bool, showRemoveButton: Bool, showDownloadButton: Bool, enableDownloadButton: Bool, dataFileIndex: Int) {
        bottomBorderView.isHidden = !showBottomBorder
        if signingFileNameActionsStackView != nil {
            signingFileNameActionsStackView.isAccessibilityElement = false
        }
        if cryptoFileNameActionsStackView != nil {
            cryptoFileNameActionsStackView.isAccessibilityElement = false
        }
        filenameLabel.text = name.sanitize()
        filenameLabel.resetLabelProperties()
        if signingActionsStackView != nil {
            signingActionsStackView.isAccessibilityElement = false
        }
        if cryptoActionsStackView != nil {
            cryptoActionsStackView.isAccessibilityElement = false
        }
        removeButton.isAccessibilityElement = true
        removeButton.isHidden = !showRemoveButton
        removeButton.accessibilityLabel = formatString(text: L(.fileImportRemoveFile), additionalText: filenameLabel.text?.sanitize())
        removeButton.accessibilityUserInputLabels = ["\(L(.voiceControlRemoveFile)) \(dataFileIndex + 1)"]
        saveButton.isAccessibilityElement = true
        saveButton.isHidden = !showDownloadButton
        saveButton.accessibilityLabel = formatString(text: L(.fileImportSaveFile), additionalText: filenameLabel.text?.sanitize())
        saveButton.accessibilityUserInputLabels = ["\(L(.voiceControlSaveFile)) \(dataFileIndex + 1)"]
        saveButton.isEnabled = enableDownloadButton
        self.dataFileIndex = dataFileIndex
    }
}

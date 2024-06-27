//
//  RecentContainersNameCell.swift
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


class RecentContainersNameCell : UITableViewCell {
    static let height: CGFloat = 50.0
    @IBOutlet weak var filenameLabel: ScaledLabel!
    @IBOutlet weak var separatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guard let fileNameText = filenameLabel else {
            return
        }
        self.accessibilityElements = [fileNameText]
    }
    
    func populate(filename: String, searchKeyword: String, showSeparator: Bool, row: Int) {
        separatorView.isHidden = !showSeparator
        
        let nsFilename = filename as NSString
        let searchKeywordRange = nsFilename.range(
            of: searchKeyword,
            options: String.CompareOptions.caseInsensitive,
            range: NSMakeRange(0, nsFilename.length),
            locale: nil)
        
        filenameLabel.text = filename
        filenameLabel.accessibilityUserInputLabels = ["\(L(.voiceControlFileRow)) \(row + 1)"]
        filenameLabel.resetLabelProperties()
    }
}

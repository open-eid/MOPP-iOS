//
//  SettingsHeaderCell.swift
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
protocol SettingsHeaderCellDelegate: AnyObject {
    func didDismissSettings()
}
class SettingsHeaderCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    weak var delegate: SettingsHeaderCellDelegate!
    
    @IBAction func dismissAction() {
        delegate.didDismissSettings()
    }
    
    func populate(with title:String) {
        titleLabel.text = title
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        guard let dismissUIButton: UIButton = dismissButton, let titleUILabel: UILabel = titleLabel else {
            NSLog("Unable to get dismissButton or titleLabel")
            return
        }
        self.accessibilityElements = [dismissUIButton, titleUILabel]
    }
}

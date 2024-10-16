//
//  RecentContainersHeaderCell.swift
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

protocol RecentContainersHeaderDelegate : AnyObject {
    func recentContainersHeaderDismiss()
}


class RecentContainersHeaderCell : UITableViewCell {
    weak var delegate: RecentContainersHeaderDelegate!
    @IBOutlet weak var recentDocumentsTitle: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    @IBAction func dismissAction() {
        delegate.recentContainersHeaderDismiss()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        recentDocumentsTitle.isAccessibilityElement = true
        recentDocumentsTitle.text = L(.signingRecentContainers)
        dismissButton.isAccessibilityElement = true
        dismissButton.setTitle(L(.closeButton))
    }
}

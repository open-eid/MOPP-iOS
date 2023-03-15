//
//  ContainerSearchCell.swift
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


class ContainerSearchCell: UITableViewCell {
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let searchField = searchBar.value(forKey: "searchField") as? UITextField {
            searchField.placeholder = L(LocKey.cryptoLdapSearchPlaceholder)
            searchField.heightAnchor.constraint(equalToConstant: 58).isActive = true
            searchField.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor).isActive = true
            searchField.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor).isActive = true

            if #unavailable(iOS 13.0) {
                let scaledFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: searchField.font ?? UIFont(name: "Roboto-Regular", size: 16) ?? UIFont())
                searchField.font = UIFont(name: "Roboto-Regular", size: scaledFont.pointSize)
            }
            searchField.translatesAutoresizingMaskIntoConstraints = false
            searchField.adjustsFontForContentSizeCategory = true
            searchField.adjustsFontSizeToFitWidth = true
        }
    }
}

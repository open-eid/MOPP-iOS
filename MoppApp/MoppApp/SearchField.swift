//
//  SearchField.swift
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

class SearchField: ScaledTextField {
    
    var onSearchIconTapped: (() -> Void)?
    
    let clearButton = UIButton(type: .custom)
    
    override func awakeFromNib() {
        self.backgroundColor = .white
        self.borderStyle = .none
        self.layer.cornerRadius = 8.0
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1).cgColor

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .lightGray

        let iconSize = CGSize(width: self.font?.lineHeight ?? 16, height: self.font?.lineHeight ?? 16)
        let iconMargin: CGFloat = 8
        searchIcon.frame = CGRect(x: iconMargin, y: 0, width: iconSize.width, height: iconSize.height)
        searchIcon.contentMode = .scaleAspectFit
        let iconContainerView = UIView(frame: CGRect(x: 0, y: 0, width: iconSize.width + iconMargin * 2, height: iconSize.height))
        iconContainerView.contentMode = .scaleAspectFit
        iconContainerView.addSubview(searchIcon)
        iconContainerView.accessibilityLabel = L(.cryptoRecipientSearch)
        iconContainerView.isAccessibilityElement = true
        iconContainerView.accessibilityTraits = [.button]
        self.leftView = iconContainerView
        self.leftViewMode = .always

        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.addTarget(self, action: #selector(clearText), for: .touchUpInside)
        clearButton.frame = CGRect(x: -iconMargin, y: 0, width: iconSize.height, height: iconSize.height)
        clearButton.tintColor = .lightGray
        rightView = clearButton
        rightViewMode = .whileEditing
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let searchIconView = self.leftView {
            searchIconView.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(searchIconTapped))
            searchIconView.addGestureRecognizer(tapGesture)
        }
    }
    
    @objc func searchIconTapped(_ sender: UITapGestureRecognizer) {
        onSearchIconTapped?()
    }
    
    @objc func clearText() {
        text = ""
    }
}

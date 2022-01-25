//
//  ContainerTableViewHeaderView.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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

protocol ContainerTableViewHeaderDelegate : AnyObject {
    func didTapContainerHeaderButton()
}

class ContainerTableViewHeaderView: UIView {
    static let height: CGFloat = 60
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    weak var delegate: ContainerTableViewHeaderDelegate? = nil
    
    var gradientLayer: CAGradientLayer!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let topColor = UIColor.white.withAlphaComponent(1.0)
        let botColor = UIColor.white.withAlphaComponent(0.8)
        createGradientLayer(topColor: topColor, bottomColor: botColor)
    }
    
    func populate(withTitle title: String, showAddButton: Bool) {
        addButton.isHidden = !showAddButton
        addButton.accessibilityLabel = showAddButton ? L(.containerHeaderFilesAddFile) : ""
        titleLabel.text = title
        if isNonDefaultPreferredContentSizeCategory() {
            titleLabel.font = UIFont.setCustomFont(font: .medium, nil, .body)
            titleLabel.numberOfLines = 3
            titleLabel.lineBreakMode = .byWordWrapping
        }
    }
    
    @IBAction func addAction() {
        delegate?.didTapContainerHeaderButton()
    }
}

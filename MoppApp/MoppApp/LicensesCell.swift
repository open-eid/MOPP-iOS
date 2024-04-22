//
//  LicensesCell.swift
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

import UIKit

class LicensesCell: UITableViewCell {
    
    @IBOutlet weak var name: ScaledLabel!
    @IBOutlet weak var license: ScaledLabel!
    @IBOutlet weak var url: ScaledLabel!

    @IBOutlet weak var licenseStackView: UIStackView!

    func populate(dependencyName: String, dependencyLicense: String, dependencyUrl: String) {
        name.text = dependencyName
        license.text = dependencyLicense
        url.text = dependencyUrl
        
        url.textColor = .link
        if let urlText = url.text {
            let urlAttributedString = NSMutableAttributedString(string: urlText)
            urlAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.link, range: NSRange(location: 0, length: urlAttributedString.length))
            urlAttributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: urlAttributedString.length))
            
            url.attributedText = urlAttributedString
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLinkTap(_:)))
            url.addGestureRecognizer(tapGesture)
            
            licenseStackView.isAccessibilityElement = false
            AccessibilityUtil.setAccessibilityElementsInStackView(stackView: self.licenseStackView, isAccessibilityElement: true)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        isAccessibilityElement = false
        isUserInteractionEnabled = true
        
        guard let nameUILabel: UILabel = name, let licenseUILabel: UILabel = license, let urlUILabel: UILabel = url else {
            printLog("Unable to get nameLabel, licenseLabel or urlLabel")
            return
        }
        self.accessibilityElements = [nameUILabel, licenseUILabel, urlUILabel]
    }
    
    @objc func handleLinkTap(_ sender: UITapGestureRecognizer) {
        if let link = url.text, let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }
}

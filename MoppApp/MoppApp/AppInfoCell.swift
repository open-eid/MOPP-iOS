//
//  AppInfoCell.swift
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

import UIKit

class AppInfoCell: UITableViewCell {
    
    @IBOutlet weak var fundLogo: UIImageView!
    
    @IBOutlet weak var digidocVersion: ScaledLabel!
    @IBOutlet weak var appIssuer: ScaledLabel!
    @IBOutlet weak var appContact: ScaledLabel!
    @IBOutlet weak var additionalLicensesLabel: ScaledLabel!

    @IBOutlet weak var infoStackView: UIStackView!
    
    func populate() {
        let appLanguageID = DefaultsHelper.moppLanguageID

        fundLogo.isAccessibilityElement = true
        
        if appLanguageID == "et" {
            fundLogo.image = UIImage(named: "main_about_fonds_et")
        } else {
            fundLogo.image = UIImage(named: "main_about_fonds_en")
        }

        fundLogo.accessibilityLabel = L(.infoAppLogoAccessibility)
        
        digidocVersion.text = "\(L(.infoAppVersion)) \(MoppApp.versionString)"
        digidocVersion.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont(name: MoppFontName.bold.rawValue, size: 21)!)
        appIssuer.text = L(.infoAppIssuer)
        appContact.text = L(.infoAppContact)
        additionalLicensesLabel.text = L(.infoAppAdditionalLicensesLabel)
        additionalLicensesLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont(name: MoppFontName.bold.rawValue, size: 21)!)
        
        let contactText = "\(L(.infoAppContact)) \(L(.infoAppContactDisplayLink))"
        let attributedString = NSMutableAttributedString(string: contactText)
        
        if let range = contactText.range(of: L(.infoAppContactDisplayLink)) {
            let nsRange = NSRange(range, in: contactText)
            
            attributedString.addAttribute(.link, value: L(.infoAppContactLink), range: nsRange)
            attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
            attributedString.addAttribute(NSAttributedString.Key.underlineColor, value: UIColor.blue, range: nsRange)
        }
        
        appContact.attributedText = attributedString
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLinkTap(_:)))
        appContact.addGestureRecognizer(tapGesture)
        
        infoStackView.isAccessibilityElement = false
        AccessibilityUtil.setAccessibilityElementsInStackView(stackView: self.infoStackView, isAccessibilityElement: true)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        isAccessibilityElement = false
        isUserInteractionEnabled = true
        
        guard let fundUILogo = fundLogo, let digidocUIVersionLabel = digidocVersion, let appUIIssuerLabel = appIssuer, let appUIContactLabel = appContact, let additionalLicensesUILabel = additionalLicensesLabel else {
            printLog("Unable to get fundLogo, digidocVersion, appIssuer, appContact or additionalLicensesLabel")
            return
        }
        
        self.accessibilityElements = [fundUILogo, digidocUIVersionLabel, appUIIssuerLabel, appUIContactLabel, additionalLicensesUILabel]
    }
    
    @objc func handleLinkTap(_ sender: UITapGestureRecognizer) {
        if let url = URL(string: L(.infoAppContactLink)) {
            UIApplication.shared.open(url)
        }
    }
}

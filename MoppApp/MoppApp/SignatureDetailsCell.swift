//
//  SignatureDetailsCell.swift
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

class SignatureDetailsCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    func populate(signatureDetail: SignatureDetail) {
        titleLabel.text = signatureDetail.title
        contentLabel.text = signatureDetail.value
        
        titleLabel.accessibilityLabel = signatureDetail.title
        contentLabel.accessibilityLabel = signatureDetail.value
        
        titleLabel.textColor = UIColor.moppDetailText
        contentLabel.textColor = UIColor.moppDetailValue
        
        if signatureDetail.x509Certificate != nil && signatureDetail.secCertificate != nil {
            contentLabel.textColor = UIColor.link
            contentLabel.accessibilityTraits = .button
        } else {
            titleLabel.textColor = UIColor.moppDetailText
            contentLabel.textColor = UIColor.moppDetailValue
        }
    }
}

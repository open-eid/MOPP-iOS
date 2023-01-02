//
//  CertificateDetailsCell.swift
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
import ASN1Decoder

class CertificateDetailsCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    @IBOutlet weak var separatorLine: UIView!
    
    func populate(certificateDetail: CertificateDetail) {
        titleLabel.text = certificateDetail.title
        contentLabel.text = certificateDetail.value
        
        titleLabel.accessibilityLabel = certificateDetail.title
        contentLabel.accessibilityLabel = certificateDetail.value
        
        titleLabel.textColor = UIColor.moppDetailText
        contentLabel.textColor = UIColor.moppDetailValue
        
        separatorLine.frame = CGRect(x: 0, y: 0, width: separatorLine.frame.width, height: separatorLine.frame.height / 2)
        separatorLine.alpha = 0.5
        
        if certificateDetail.isSubValue {
            separatorLine.isHidden = true
        } else {
            separatorLine.isHidden = false
        }
    }
}

//
//  ContainerSignatureCell.swift
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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

protocol ContainerSignatureDelegate: class {
    func containerSignatureRemove(signatureIndex: Int)
}


class ContainerSignatureCell: UITableViewCell {
    static let height: CGFloat = 60
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var personalCodeLabel: UILabel!
    @IBOutlet weak var signedInfoLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var bottomBorderView: UIView!
    @IBOutlet weak var statusIconImageView: UIImageView!
    @IBOutlet weak var removeButton: UIButton!
    
    weak var delegate: ContainerSignatureDelegate? = nil
    
    enum ColorTheme {
        case neutral
        case showInvalid
        case showSuccess
    }
    
    enum Kind {
        case signature
        case timestamp
    }
    
    var kind: Kind = .signature
    var signatureIndex: Int!
    
    @IBAction func removeAction() {
        delegate?.containerSignatureRemove(signatureIndex: signatureIndex)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func populate(with signature: MoppLibSignature, kind: Kind, showBottomBorder: Bool, showRemoveButton: Bool, signatureIndex: Int) {
        self.kind = kind
        self.signatureIndex = signatureIndex

        nameLabel.text = signature.subjectName
        
        signedInfoLabel.text = L(LocKey.containerSignatureSigned, [MoppDateFormatter.shared.hHmmssddMMYYYY(toString: signature.timestamp)])
        
        iconImageView.image = kind == .signature ?
            UIImage(named: "Icon_Allkiri_small") :
            UIImage(named: "Icon_ajatempel")
        bottomBorderView.isHidden = !showBottomBorder
        removeButton.isHidden = !showRemoveButton
        
        let colorTheme = signature.isValid ? ColorTheme.showSuccess : ColorTheme.showInvalid
        switch colorTheme {
        case .neutral:
            nameLabel.textColor = UIColor.moppText
            statusIconImageView.image = UIImage(named: "icon_check")
        case .showInvalid:
            nameLabel.textColor = UIColor.moppWarning
            statusIconImageView.image = UIImage(named: "icon_alert_red")
        case .showSuccess:
            nameLabel.textColor = UIColor.moppText
            statusIconImageView.image = UIImage(named: "icon_check")
        }
    }
}

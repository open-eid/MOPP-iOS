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
    @IBOutlet weak var signatureStatusLabel: UILabel!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var testSignatureLabel: UILabel!
    
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
        var signatureStatus : NSMutableAttributedString
        switch (signature.status) {
            case MoppLibSignatureStatus.ValidTest:
                signatureStatus = getSignatureStatusText(translationPrefix: L(LocKey.containerSignatureStatusValid), translationSufix: "", valid: true)
                showTestSignatureLabel()
            case MoppLibSignatureStatus.Valid:
                testSignatureLabel.isHidden = true
                signatureStatus = getSignatureStatusText(translationPrefix: L(LocKey.containerSignatureStatusValid), translationSufix: "", valid: true)
            case MoppLibSignatureStatus.Warning:
                testSignatureLabel.isHidden = true
                signatureStatus = getSignatureStatusText(translationPrefix: L(LocKey.containerSignatureStatusValid), translationSufix: L(LocKey.containerSignatureStatusWarning), valid: true)
            case MoppLibSignatureStatus.NonQSCD:
                testSignatureLabel.isHidden = true
                signatureStatus = getSignatureStatusText(translationPrefix: L(LocKey.containerSignatureStatusValid), translationSufix: L(LocKey.containerSignatureStatusNonQscd), valid: true)
            case MoppLibSignatureStatus.UnknownStatus:
                testSignatureLabel.isHidden = true
                signatureStatus = getSignatureStatusText(translationPrefix: L(LocKey.containerSignatureStatusUnknown), translationSufix: "", valid: false)
            case MoppLibSignatureStatus.Invalid:
                testSignatureLabel.isHidden = true
                signatureStatus = getSignatureStatusText(translationPrefix: L(LocKey.containerSignatureStatusInvalid), translationSufix: "", valid: false)
        }
        
        signatureStatusLabel.attributedText = signatureStatus
        checkSignatureValidity(signature: signature)
        
        iconImageView.image = kind == .signature ?
            UIImage(named: "Icon_Allkiri_small") :
            UIImage(named: "Icon_ajatempel")
        bottomBorderView.isHidden = !showBottomBorder
        removeButton.isHidden = !showRemoveButton

    }
    
    func getSignatureStatusText(translationPrefix: String, translationSufix: String, valid: Bool) -> NSMutableAttributedString{
        
        let signatureStatusText = translationPrefix + " " + translationSufix
        let signatureStatus = NSMutableAttributedString(string: signatureStatusText)
        let mainColor: UIColor
        if(valid){
            mainColor = UIColor.moppSuccessText
        }else{
            mainColor = UIColor.moppError
        }
        signatureStatus.addAttribute(NSAttributedStringKey.foregroundColor, value: mainColor, range: NSRange(location:0,length:translationPrefix.count))
        signatureStatus.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.moppWarningText, range: NSRange(location:translationPrefix.count+1,length:translationSufix.count))
        return signatureStatus
    }
    
    private func checkSignatureValidity(signature: MoppLibSignature) -> Void {
        if (signature.timestamp == nil) {
            signedInfoLabel.text = ""
        } else {
            signedInfoLabel.text = L(LocKey.containerSignatureSigned, [MoppDateFormatter.shared.hHmmssddMMYYYY(toString: signature.timestamp)])
        }
        if (signature.subjectName == "") {
            nameLabel.text = L(LocKey.containerTimestampInvalid)
        } else {
            nameLabel.text = signature.subjectName
        }
    }
    
    private func showTestSignatureLabel() {
        testSignatureLabel.layer.zPosition = 999;
        testSignatureLabel.isHidden = false
        testSignatureLabel.text = L(LocKey.conatinerSignatureTestSignatureTitle)
        testSignatureLabel.textColor = .black
        testSignatureLabel.layer.masksToBounds = true
        testSignatureLabel.layer.cornerRadius = 4
    }
}

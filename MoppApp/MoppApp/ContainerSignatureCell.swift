//
//  ContainerSignatureCell.swift
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

protocol ContainerSignatureDelegate: AnyObject {
    func showRoleDetails(signatureIndex: Int)
    func containerSignatureRemove(signatureIndex: Int)
}


class ContainerSignatureCell: UITableViewCell {
    static let height: CGFloat = 60
    @IBOutlet weak var nameLabel: ScaledLabel!
    @IBOutlet weak var personalCodeLabel: ScaledLabel!
    @IBOutlet weak var roleInfo: ScaledLabel!
    @IBOutlet weak var signedInfoLabel: ScaledLabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var bottomBorderView: UIView!
    @IBOutlet weak var signatureStatusLabel: ScaledLabel!
    @IBOutlet weak var signatureInfoView: UIView!
    @IBOutlet weak var removeButton: ScaledButton!
    
    weak var delegate: ContainerSignatureDelegate? = nil
    
    var signatureStatus: MoppLibSignatureStatus?

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
    
    @objc func showRoleDetails(sender: UITapGestureRecognizer) {
        delegate?.showRoleDetails(signatureIndex: signatureIndex)
    }

    @IBAction func removeAction() {
        delegate?.containerSignatureRemove(signatureIndex: signatureIndex)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func populate(with signature: MoppLibSignature, kind: Kind, isTimestamp: Bool, showBottomBorder: Bool, showRemoveButton: Bool, showRoleDetailsButton: Bool, signatureIndex: Int) {
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(showRoleDetails(sender:)))
        signatureInfoView.isUserInteractionEnabled = true
        signatureInfoView.addGestureRecognizer(tapRecognizer)
        
        self.kind = kind
        self.signatureIndex = signatureIndex
        var signatureStatusDescription : NSMutableAttributedString
        self.signatureStatus = signature.status
        
        switch (signature.status) {
            case MoppLibSignatureStatus.Valid:
            signatureStatusDescription = kind == .timestamp ? getSignatureStatusText(translationPrefix: L(LocKey.containerTimestampValid), translationSufix: "", valid: true) : getSignatureStatusText(translationPrefix: L(LocKey.containerSignatureStatusValid), translationSufix: "", valid: true)
            case MoppLibSignatureStatus.Warning:
            signatureStatusDescription = kind == .timestamp ? getSignatureStatusText(translationPrefix: L(LocKey.containerTimestampValid), translationSufix: L(LocKey.containerSignatureStatusWarning), valid: true) : getSignatureStatusText(translationPrefix: L(LocKey.containerSignatureStatusValid), translationSufix: L(LocKey.containerSignatureStatusWarning), valid: true)
            case MoppLibSignatureStatus.NonQSCD:
            signatureStatusDescription = kind == .timestamp ? getSignatureStatusText(translationPrefix: L(LocKey.containerTimestampValid), translationSufix: L(LocKey.containerSignatureStatusNonQscd), valid: true) : getSignatureStatusText(translationPrefix: L(LocKey.containerSignatureStatusValid), translationSufix: L(LocKey.containerSignatureStatusNonQscd), valid: true)
            case MoppLibSignatureStatus.UnknownStatus:
            signatureStatusDescription = kind == .timestamp ? getSignatureStatusText(translationPrefix: L(LocKey.containerTimestampUnknown), translationSufix: "", valid: false) : getSignatureStatusText(translationPrefix: L(LocKey.containerSignatureStatusUnknown), translationSufix: "", valid: false)
            case MoppLibSignatureStatus.Invalid:
            signatureStatusDescription = kind == .timestamp ? getSignatureStatusText(translationPrefix: L(LocKey.containerTimestampInvalid), translationSufix: "", valid: false) : getSignatureStatusText(translationPrefix: L(LocKey.containerSignatureStatusInvalid), translationSufix: "", valid: false)
        @unknown default:
            signatureStatusDescription = NSMutableAttributedString(string: "")
        }
        
        signatureStatusLabel.accessibilityUserInputLabels = [""]
        signatureStatusLabel.attributedText = signatureStatusDescription
        checkSignatureValidity(signature: signature)
        
        iconImageView.image = UIImage(named: (kind == .signature)
            ? (isTimestamp ? "Icon_digitempel" : "Icon_Allkiri_small")
            : "Icon_ajatempel")
        
        setRoleText(signature: signature)
        
        bottomBorderView.isHidden = !showBottomBorder
        removeButton.isHidden = !showRemoveButton
        removeButton.accessibilityUserInputLabels = ["\(L(.voiceControlRemoveSignature)) \(signatureIndex + 1)"]
        signatureInfoView.isHidden = isTimestamp || !showRoleDetailsButton
        signatureInfoView.accessibilityLabel = L(.roleAndAddress)
        signatureInfoView.accessibilityUserInputLabels = ["\(L(.voiceControlRoleAndAddress)) \(signatureIndex + 1)"]
    }
    
    func getSignatureStatusText(translationPrefix: String, translationSufix: String, valid: Bool) -> NSMutableAttributedString{
        
        let signatureStatusText = translationPrefix + " " + translationSufix
        let signatureStatus = NSMutableAttributedString(string: signatureStatusText)
        let mainColor: UIColor
        if (valid) {
            mainColor = UIColor.moppGreenValid
        } else {
            mainColor = UIColor.moppError
        }
        signatureStatus.addAttribute(NSAttributedString.Key.foregroundColor, value: mainColor, range: NSRange(location:0,length:translationPrefix.count))
        signatureStatus.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.moppWarningTextDarker, range: NSRange(location:translationPrefix.count+1,length:translationSufix.count))
        return signatureStatus
    }
    
    func setRoleText(signature: MoppLibSignature) {
        roleInfo.isHidden = signature.roleAndAddressData.roles.isEmpty
        roleInfo.text = signature.roleAndAddressData.roles.joined(separator: " / ")
        setNeedsUpdateConstraints()
        roleInfo.resetLabelProperties()
    }
    
    private func checkSignatureValidity(signature: MoppLibSignature) -> Void {
        if let timestamp = ISO8601DateFormatter().date(from: signature.timestamp) {
            signedInfoLabel.text = L(LocKey.containerSignatureSigned, [MoppDateFormatter.shared.hHmmssddMMYYYY(toString: timestamp)])
        } else {
            signedInfoLabel.text = ""
        }
        if (signature.subjectName == "") {
            nameLabel.text = L(LocKey.containerTimestampInvalid)
        } else {
            nameLabel.text = signature.subjectName
        }
    }
    
    deinit {
        printLog("Deinit ContainerSignatureCell")
    }
}

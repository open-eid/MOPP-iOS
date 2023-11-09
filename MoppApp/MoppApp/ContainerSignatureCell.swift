//
//  ContainerSignatureCell.swift
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

protocol ContainerSignatureDelegate: AnyObject {
    func showRoleDetails(signatureIndex: Int)
    func containerSignatureRemove(signatureIndex: Int)
}


class ContainerSignatureCell: UITableViewCell {
    static let height: CGFloat = 60
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var personalCodeLabel: UILabel!
    @IBOutlet weak var roleInfo: UILabel!
    @IBOutlet weak var signedInfoLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var bottomBorderView: UIView!
    @IBOutlet weak var signatureStatusLabel: UILabel!
    @IBOutlet weak var signatureInfoView: UIView!
    @IBOutlet weak var removeButton: UIButton!
    
    weak var delegate: ContainerSignatureDelegate? = nil
    
    var signatureStatus: MoppLibSignatureStatus?
    
    #if USE_TEST_DDS
        let useTestDDS = true
    #else
        let useTestDDS = false
    #endif
    
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
    }
    
    func getSignatureStatusText(translationPrefix: String, translationSufix: String, valid: Bool) -> NSMutableAttributedString{
        
        let signatureStatusText = translationPrefix + " " + translationSufix
        let signatureStatus = NSMutableAttributedString(string: signatureStatusText)
        let mainColor: UIColor
        if(valid){
            mainColor = UIColor.moppSuccessTextDarker
        }else{
            mainColor = UIColor.moppError
        }
        signatureStatus.addAttribute(NSAttributedString.Key.foregroundColor, value: mainColor, range: NSRange(location:0,length:translationPrefix.count))
        signatureStatus.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.moppWarningTextDarker, range: NSRange(location:translationPrefix.count+1,length:translationSufix.count))
        return signatureStatus
    }
    
    func setRoleText(signature: MoppLibSignature) {
        let rolesData = signature.roleAndAddressData.roles
        if let roles = rolesData, !roles.isEmpty {
            roleInfo.text = roles.joined(separator: " / ")
            roleInfo.isHidden = false
            setNeedsUpdateConstraints()
        } else {
            roleInfo.text = ""
            roleInfo.isHidden = true
            setNeedsUpdateConstraints()
        }
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
    
    deinit {
        printLog("Deinit ContainerSignatureCell")
    }
}

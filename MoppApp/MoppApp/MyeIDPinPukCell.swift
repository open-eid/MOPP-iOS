//
//  MyeIDPinPukCell.swift
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
protocol MyeIDPinPukCellDelegate: class {
    func didTapChangeCodeButton()
}

class MyeIDPinPukCell: UITableViewCell {
    weak var delegate: MyeIDPinPukCellDelegate? = nil
    
    var kind: MyeIDInfoManager.PinPukCell.Kind!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var certInfoLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var linkButton: UIButton!
    @IBOutlet weak var bottomLine: UIView!
    @IBOutlet weak var hideChangeButtonCSTR: NSLayoutConstraint!
    @IBOutlet weak var showChangeButtonCSTR: NSLayoutConstraint!
    
    @IBAction func changeCodeAction() {
        MyeIDInfoManager.shared.delegate?.didTapChangePinPukCode(kind: kind)
    }
    
    func populate(pinPukCellInfo: MyeIDInfoManager.PinPukCell.Info) {
        contentView.bounds = bounds
        layoutIfNeeded()
        
        errorLabel.preferredMaxLayoutWidth = errorLabel.frame.width
        certInfoLabel.preferredMaxLayoutWidth = certInfoLabel.frame.width
        
        kind = pinPukCellInfo.kind
        titleLabel.text = pinPukCellInfo.title
        linkLabel.attributedText = NSAttributedString(string: pinPukCellInfo.linkText, attributes: [.underlineStyle : NSUnderlineStyle.styleSingle.rawValue])
        button.setTitle(pinPukCellInfo.buttonText)
        
        let pin1Blocked = MyeIDInfoManager.shared.retryCounts.pin1 == 0
        let pin2Blocked = MyeIDInfoManager.shared.retryCounts.pin2 == 0
        let pukBlocked = MyeIDInfoManager.shared.retryCounts.puk == 0
        
        if kind == .pin1 {
            if pin1Blocked {
                linkLabel.isHidden = true
                linkLabel.text = nil
                linkButton.isEnabled = false
                errorLabel.isHidden = false
                errorLabel.text = L(.myEidInfoPin1BlockedMessage)
                button.setTitle(L(.myEidUnblockPin1ButtonTitle))
                if pukBlocked {
                    showChangeButton(false)
                    button.backgroundColor = UIColor.moppDescriptiveText
                } else {
                    showChangeButton(true)
                    button.backgroundColor = UIColor.moppBase
                }
            } else {
                linkLabel.isHidden = false
                titleLabel.text = pinPukCellInfo.title
                linkButton.isEnabled = true
                errorLabel.isHidden = true
                errorLabel.text = nil
                button.setTitle(pinPukCellInfo.buttonText)
                showChangeButton(true)
                button.backgroundColor = UIColor.moppBase
            }
        }
        else if kind == .pin2 {
            if pin2Blocked {
                linkLabel.isHidden = true
                linkLabel.text = nil
                linkButton.isEnabled = false
                errorLabel.isHidden = false
                errorLabel.text = L(.myEidInfoPin2BlockedMessage)
                button.setTitle(L(.myEidUnblockPin2ButtonTitle))
                if pukBlocked {
                    showChangeButton(false)
                    button.backgroundColor = UIColor.moppDescriptiveText
                } else {
                    showChangeButton(true)
                    button.backgroundColor = UIColor.moppBase
                }
            } else {
                linkLabel.isHidden = false
                titleLabel.text = pinPukCellInfo.title
                linkButton.isEnabled = true
                errorLabel.isHidden = true
                errorLabel.text = nil
                button.setTitle(pinPukCellInfo.buttonText)
                showChangeButton(true)
                button.backgroundColor = UIColor.moppBase
            }
        }
        else if kind == .puk {
            if pukBlocked {
                linkLabel.isHidden = false
                linkLabel.attributedText = NSAttributedString(string: L(.myEidHowToGetCodesMessage), attributes: [.underlineStyle : NSUnderlineStyle.styleSingle.rawValue])
                linkButton.isEnabled = true
                errorLabel.isHidden = false
                errorLabel.text = L(.myEidInfoPukBlockedMessage)
                button.setTitle(pinPukCellInfo.buttonText)
                showChangeButton(false)
                button.backgroundColor = UIColor.moppDescriptiveText
            } else {
                linkLabel.isHidden = true
                linkLabel.text = nil
                titleLabel.text = pinPukCellInfo.title
                linkButton.isEnabled = false
                errorLabel.isHidden = true
                errorLabel.text = nil
                button.setTitle(pinPukCellInfo.buttonText)
                let bothCertsExpired = !MyeIDInfoManager.shared.isAuthCertValid && !MyeIDInfoManager.shared.isSignCertValid
                showChangeButton(!bothCertsExpired)
                button.backgroundColor = UIColor.moppBase
            }
        }
    }
    
    func populate2(pinPukCellInfo: MyeIDInfoManager.PinPukCell.Info) {
        if let certInfoText = pinPukCellInfo.certInfoText {
            certInfoLabel.text = certInfoText
        } else {
            certInfoLabel.text = nil
            certInfoLabel.font = nil
            certInfoLabel.attributedText = MyeIDInfoManager.shared.certInfoAttributedString(for: kind)
            certInfoLabel.setNeedsDisplay()
        }
    }
    
    func showChangeButton(_ show:Bool) {
        button.isHidden = !show
        button.isEnabled = show
        showChangeButtonCSTR.priority = show ? UILayoutPriority.defaultHigh : UILayoutPriority.defaultLow
        hideChangeButtonCSTR.priority = show ? UILayoutPriority.defaultLow : UILayoutPriority.defaultHigh
    }
}

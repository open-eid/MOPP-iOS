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
    weak var infoManager: MyeIDInfoManager!
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
    @IBOutlet weak var showCertsExpiredCSTR: NSLayoutConstraint!
    @IBOutlet weak var hideCertsExpiredCSTR: NSLayoutConstraint!
    
    @IBAction func changeCodeAction() {
        guard let kind = kind else { return }
    
        var actionType: MyeIDChangeCodesModel.ActionType? = nil
        switch kind {
        case .pin1:
            if infoManager.retryCounts.pin1 == 0 {
                actionType = .unblockPin1
            } else {
                actionType = .changePin1
            }
        case .pin2:
            if infoManager.retryCounts.pin2 == 0 {
                actionType = .unblockPin2
            } else {
                actionType = .changePin2
            }
        case .puk:
            actionType = .changePuk
        }
        
        if let actionType = actionType {
            infoManager.delegate?.didTapChangePinPukCode(actionType: actionType)
        }
    }
    
    @IBAction func linkAction() {
        guard let kind = kind else { return }
        
        var actionType: MyeIDChangeCodesModel.ActionType? = nil
        switch kind {
        case .pin1:
            actionType = .unblockPin1
        case .pin2:
            actionType = .unblockPin2
        case .puk:
            var url: URL!
            let appLanguageID = DefaultsHelper.moppLanguageID
            if appLanguageID  == "et" {
                url = URL(string: "https://www.id.ee/index.php?id=30133")
            }
            else if appLanguageID == "ru" {
                url = URL(string: "https://www.id.ee/?lang=ru&id=33922")
            }
            else {
                url = URL(string: "https://www.id.ee/?lang=en&id=31027")
            }
            MoppApp.instance.open(url, options: [:], completionHandler: nil)
        }
        
        if let actionType = actionType {
            infoManager.delegate?.didTapChangePinPukCode(actionType: actionType)
        }
    }
    
    func populate(pinPukCellInfo: MyeIDInfoManager.PinPukCell.Info) {
        contentView.bounds = bounds
        layoutIfNeeded()
        
        titleLabel.isAccessibilityElement = true
        certInfoLabel.isAccessibilityElement = true
        errorLabel.isAccessibilityElement = true
        
        errorLabel.preferredMaxLayoutWidth = errorLabel.frame.width
        certInfoLabel.preferredMaxLayoutWidth = certInfoLabel.frame.width
        
        kind = pinPukCellInfo.kind
        bottomLine.isHidden = kind == .puk
        titleLabel.text = pinPukCellInfo.title

        button.setTitle(pinPukCellInfo.buttonText)
        
        let pin1Blocked = infoManager.retryCounts.pin1 == 0
        let pin2Blocked = infoManager.retryCounts.pin2 == 0
        let pukBlocked = infoManager.retryCounts.puk == 0
        
        let authCertValid = infoManager.isAuthCertValid
        let signCertValid = infoManager.isSignCertValid
        
        if kind == .pin1 {
            titleLabel.text = pinPukCellInfo.title
            showCertsExpired(!authCertValid)
            if pin1Blocked {
                showLink(false)
                showErrorLabel(true, with: L(.myEidInfoPin1BlockedMessage))
                if pukBlocked {
                    showChangeButton(false)
                    button.backgroundColor = UIColor.moppDescriptiveText
                } else {
                    showChangeButton(authCertValid, with: L(.myEidUnblockPin1ButtonTitle))
                    button.backgroundColor = UIColor.moppBase
                }
            } else {
                showLink(authCertValid && !pukBlocked)
                linkLabel.attributedText = NSAttributedString(string: pinPukCellInfo.linkText, attributes: [.underlineStyle : NSUnderlineStyle.styleSingle.rawValue])
                linkButton.accessibilityLabel = L(.myEidInfoPin1LinkText)
                errorLabel.isHidden = true
                errorLabel.text = nil
                showChangeButton(authCertValid, with: pinPukCellInfo.buttonText)
                button.backgroundColor = UIColor.moppBase
                
                if savedLastFocusElement == .changePIN1 {
                    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, button)
                } else if savedLastFocusElement == .unblockPIN1 {
                    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, linkButton)
                }
            }
        }
        else if kind == .pin2 {
            titleLabel.text = pinPukCellInfo.title
            showCertsExpired(!signCertValid)
            if pin2Blocked {
                showLink(false)
                showErrorLabel(true, with: L(.myEidInfoPin2BlockedMessage))
                if pukBlocked {
                    showChangeButton(false)
                    button.backgroundColor = UIColor.moppDescriptiveText
                } else {
                    showChangeButton(signCertValid, with: L(.myEidUnblockPin2ButtonTitle))
                    button.backgroundColor = UIColor.moppBase
                }
            } else {
                showLink(signCertValid && !pukBlocked)
                linkLabel.attributedText = NSAttributedString(string: pinPukCellInfo.linkText, attributes: [.underlineStyle : NSUnderlineStyle.styleSingle.rawValue])
                linkButton.accessibilityLabel = L(.myEidInfoPin2LinkText)
                showErrorLabel(false)
                showChangeButton(signCertValid, with: pinPukCellInfo.buttonText)
                button.backgroundColor = UIColor.moppBase
                
                if savedLastFocusElement == .changePIN2 {
                    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, button)
                } else if savedLastFocusElement == .unblockPIN2 {
                    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, linkButton)
                }
            }
        }
        else if kind == .puk {
            titleLabel.text = pinPukCellInfo.title
            if pukBlocked {
                showLink(true)
                linkLabel.attributedText = NSAttributedString(string: L(.myEidHowToGetCodesMessage), attributes: [.underlineStyle : NSUnderlineStyle.styleSingle.rawValue])
                linkButton.accessibilityLabel = L(.myEidHowToGetCodesMessage)
                showErrorLabel(true, with: L(.myEidInfoPukBlockedMessage))
                showChangeButton(false)
                button.backgroundColor = UIColor.moppDescriptiveText
            } else {
                showLink(false)
                showErrorLabel(false)
                showChangeButton(authCertValid || signCertValid, with: pinPukCellInfo.buttonText)
                button.backgroundColor = UIColor.moppBase
                
                if savedLastFocusElement == .changePUK {
                    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, button)
                }
            }
        }
        
        layoutIfNeeded()
    }
    
    func populateForWillDisplayCell(pinPukCellInfo: MyeIDInfoManager.PinPukCell.Info) {
        if let certInfoText = pinPukCellInfo.certInfoText {
            certInfoLabel.text = certInfoText
            certInfoLabel.accessibilityLabel = certInfoText
        } else {
            certInfoLabel.text = nil
            certInfoLabel.font = nil
            certInfoLabel.accessibilityLabel = nil
            certInfoLabel.attributedText = infoManager.certInfoAttributedString(for: kind)
            certInfoLabel.setNeedsDisplay()
        }
    }
    
    func showChangeButton(_ show:Bool, with title:String? = nil) {
        button.setTitle(show ? title : nil)
        button.isHidden = !show
        button.isEnabled = show
        showChangeButtonCSTR.priority = show ? UILayoutPriority.defaultHigh : UILayoutPriority.defaultLow
        hideChangeButtonCSTR.priority = show ? UILayoutPriority.defaultLow : UILayoutPriority.defaultHigh
    }
    
    func showLink(_ show:Bool, with text:String? = nil) {
        linkLabel.isHidden = !show
        linkButton.isHidden = !show
        linkButton.isEnabled = show
        linkLabel.text = show ? text : nil
        linkLabel.attributedText = nil
    }
    
    func showErrorLabel(_ show:Bool, with text:String? = nil) {
        errorLabel.attributedText = nil
        errorLabel.text = show ? text : nil
        errorLabel.accessibilityLabel = show ? text : nil
        errorLabel.isHidden = !show
    }
    
    func showCertsExpired(_ show:Bool) {
        showCertsExpiredCSTR.priority = show ? UILayoutPriority.defaultHigh : UILayoutPriority.defaultLow
        hideCertsExpiredCSTR.priority = show ? UILayoutPriority.defaultLow : UILayoutPriority.defaultHigh
    }
}

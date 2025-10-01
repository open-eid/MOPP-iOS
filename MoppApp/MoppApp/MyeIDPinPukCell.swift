//
//  MyeIDPinPukCell.swift
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
protocol MyeIDPinPukCellDelegate: AnyObject {
    func didTapChangeCodeButton()
}

class MyeIDPinPukCell: UITableViewCell {
    weak var delegate: MyeIDPinPukCellDelegate? = nil
    weak var infoManager: MyeIDInfoManager!
    var kind: MyeIDInfoManager.PinPukCell.Kind!
    var actionType: MyeIDChangeCodesModel.ActionType?
    var cellInfo: MyeIDInfoManager.PinPukCell.Info?
    var url: URL?

    @IBOutlet weak var certInfoView: UIView!
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
    
        var actionType: MyeIDChangeCodesModel.ActionType
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
        infoManager.delegate?.didTapChangePinPukCode(actionType: actionType)
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
            if let url {
                MoppApp.instance.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }
        }
        
        if let actionType = actionType {
            infoManager.delegate?.didTapChangePinPukCode(actionType: actionType)
        }
    }
    
    func setAccessibilityFocusOnButton(actionButton: UIButton?, cellKind: MyeIDChangeCodesModel.ActionType?) {
        if UIAccessibility.isVoiceOverRunning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIAccessibility.post(notification: .layoutChanged, argument: actionButton ?? self.button)
            }
        }
    }
    
    func populate(pinPukCellInfo: MyeIDInfoManager.PinPukCell.Info, shouldFocusOnElement: Bool) {
        cellInfo = pinPukCellInfo
        contentView.bounds = bounds
        layoutIfNeeded()
        
        certInfoView.isAccessibilityElement = true
        errorLabel.isAccessibilityElement = true
        
        errorLabel.preferredMaxLayoutWidth = errorLabel.frame.width
        
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
                linkLabel.attributedText = NSAttributedString(string: pinPukCellInfo.linkText, attributes: [.underlineStyle : NSUnderlineStyle.single.rawValue])
                linkButton.accessibilityLabel = L(.myEidInfoPin1LinkText)
                errorLabel.isHidden = true
                errorLabel.text = nil
                showChangeButton(authCertValid, with: pinPukCellInfo.buttonText)
                button.backgroundColor = UIColor.moppBase
                
                if UIAccessibility.isVoiceOverRunning && (infoManager.actionKind == .unblockPin1 || infoManager.actionKind == .changePin1) {
                    setAccessibilityFocusOnButton(actionButton: self.linkButton, cellKind: infoManager.actionKind)
                }
            }
        }
        else if kind == .pin2 {
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
                linkLabel.attributedText = NSAttributedString(string: pinPukCellInfo.linkText, attributes: [.underlineStyle : NSUnderlineStyle.single.rawValue])
                linkButton.accessibilityLabel = L(.myEidInfoPin2LinkText)
                showErrorLabel(false)
                showChangeButton(signCertValid, with: pinPukCellInfo.buttonText)
                button.backgroundColor = UIColor.moppBase
                
                if UIAccessibility.isVoiceOverRunning && (infoManager.actionKind == .unblockPin2 || infoManager.actionKind == .changePin2) {
                    setAccessibilityFocusOnButton(actionButton: self.linkButton, cellKind: infoManager.actionKind)
                }
            }
        }
        else if kind == .puk {
            if pukBlocked {
                showLink(true)
                url = URL(string: L(.myEidHowToGetCodesUrl))
                linkLabel.attributedText = NSAttributedString(string: L(.myEidHowToGetCodesMessage), attributes: [.underlineStyle : NSUnderlineStyle.single.rawValue])
                linkButton.accessibilityLabel = L(.myEidHowToGetCodesMessage)
                showErrorLabel(true, with: L(.myEidInfoPukBlockedMessage))
                showChangeButton(false)
                button.backgroundColor = UIColor.moppDescriptiveText
            } else {
                showLink(!infoManager.canChangePUK)
                url = URL(string: L(.myEidChangeNotAvailableUrl))
                linkLabel.attributedText = NSAttributedString(string: L(.errorAlertOpenLink), attributes: [.underlineStyle : NSUnderlineStyle.single.rawValue])
                linkButton.accessibilityLabel = L(.errorAlertOpenLink)
                showErrorLabel(!infoManager.canChangePUK, with: L(.myEidChangeNotAvailableText), color: UIColor.moppLabel)
                showChangeButton(infoManager.canChangePUK && (authCertValid || signCertValid), with: pinPukCellInfo.buttonText)
                populateForWillDisplayCell(pinPukCellInfo: pinPukCellInfo)
                button.backgroundColor = UIColor.moppBase
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
    
    func showErrorLabel(_ show:Bool, with text:String? = nil, color:UIColor = UIColor.moppError) {
        errorLabel.attributedText = nil
        errorLabel.text = show ? text : nil
        errorLabel.textColor = color
        errorLabel.accessibilityLabel = show ? text : nil
        errorLabel.isHidden = !show
    }
    
    func showCertsExpired(_ show:Bool) {
        showCertsExpiredCSTR.priority = show ? UILayoutPriority.defaultHigh : UILayoutPriority.defaultLow
        hideCertsExpiredCSTR.priority = show ? UILayoutPriority.defaultLow : UILayoutPriority.defaultHigh
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

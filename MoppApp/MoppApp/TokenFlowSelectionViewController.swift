//
//  TokenFlowSelectionViewController.swift
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
class TokenFlowSelectionViewController : MoppViewController {
    @IBOutlet weak var centerViewCenterCSTR: NSLayoutConstraint!
    @IBOutlet weak var centerViewOutofscreenCSTR: NSLayoutConstraint!
    @IBOutlet weak var centerViewKeyboardCSTR: NSLayoutConstraint!
    @IBOutlet var tokenFlowMethodButtons: [UIButton]!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var tokenNavbar: UIView!
    @IBOutlet weak var mobileIDButton: UIButton!
    @IBOutlet weak var smartIDButton: UIButton!
    @IBOutlet weak var idCardButton: UIButton!
    
    var isFlowForDecrypting = false
    weak var mobileIdEditViewControllerDelegate: MobileIDEditViewControllerDelegate!
    weak var smartIdEditViewControllerDelegate: SmartIDEditViewControllerDelegate!
    weak var idCardSignViewControllerDelegate: IdCardSignViewControllerDelegate?
    weak var idCardDecryptViewControllerDelegate: IdCardDecryptViewControllerDelegate?
    
    var containerPath: String!
    
    var isSwitchingBlockedByTransition: Bool = false
    
    enum TokenFlowMethodButtonID: String {
        case mobileID
        case smartID
        case idCard
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeButtonTitles()
        
        if #available(iOS 12, *) {
            self.accessibilityElements = [mobileIDButton, containerView, smartIDButton, containerView, idCardButton, containerView]
        } else {
            self.view.accessibilityElements = [mobileIDButton, containerView, smartIDButton, containerView, idCardButton, containerView]
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let signMethod = TokenFlowMethodButtonID(rawValue: DefaultsHelper.signMethod) ?? .mobileID
        if isFlowForDecrypting {
            tokenNavbar.isHidden = true
            changeTokenFlowMethod(newSignMethod: .idCard)
        } else {
            changeTokenFlowMethod(newSignMethod: signMethod)
        }
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        
        UIView.animate(withDuration: 0.35) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
        
        centerViewCenterCSTR.priority = .defaultLow
        centerViewOutofscreenCSTR.priority = .defaultHigh
        
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: {
            self.centerViewCenterCSTR.priority = .defaultHigh
            self.centerViewOutofscreenCSTR.priority = .defaultLow
            self.view.layoutIfNeeded()
        }) { _ in
            
        }
    }
    
    func localizeButtonTitles() {
        tokenFlowMethodButtons.forEach {
            let id = TokenFlowMethodButtonID(rawValue: $0.accessibilityIdentifier!)!
            switch id {
            case .idCard:
                $0.setTitle(L(.signTitleIdCard))
                idCardButton.accessibilityLabel = setTabAccessibilityLabel(isTabSelected: false, tabName: L(.signTitleIdCard), positionInRow: "3", viewCount: "3")
            case .mobileID:
                $0.setTitle(L(.signTitleMobileId))
                mobileIDButton.accessibilityLabel = setTabAccessibilityLabel(isTabSelected: false, tabName: L(.signTitleMobileId), positionInRow: "1", viewCount: "3")
            case .smartID:
                $0.setTitle(L(.signTitleSmartId))
                smartIDButton.accessibilityLabel = setTabAccessibilityLabel(isTabSelected: false, tabName: L(.signTitleSmartId), positionInRow: "2", viewCount: "3")
            }
        }
    }
}

extension TokenFlowSelectionViewController {
    func changeTokenFlowMethod(newSignMethod: TokenFlowMethodButtonID) {
        let oldViewController = childViewControllers.first
        let newViewController: MoppViewController!
        selectButton(buttonID: newSignMethod)
        switch newSignMethod {
        case .idCard:
            let idCardSignVC = UIStoryboard.tokenFlow.instantiateViewController(of: IdCardViewController.self)
                idCardSignVC.containerPath = containerPath
            if isFlowForDecrypting {
                idCardSignVC.isActionDecryption = true
                idCardSignVC.decryptDelegate = idCardDecryptViewControllerDelegate
            } else {
                idCardSignVC.signDelegate = idCardSignViewControllerDelegate
            }
            idCardSignVC.keyboardDelegate = self
            newViewController = idCardSignVC
        case .mobileID:
            let mobileIdEditVC = UIStoryboard.tokenFlow.instantiateViewController(of: MobileIDEditViewController.self)
                mobileIdEditVC.delegate = mobileIdEditViewControllerDelegate
            newViewController = mobileIdEditVC
        case .smartID:
            let smartIdEditVC = UIStoryboard.tokenFlow.instantiateViewController(of: SmartIDEditViewController.self)
                smartIdEditVC.delegate = smartIdEditViewControllerDelegate
            newViewController = smartIdEditVC
        }
        
        oldViewController?.willMove(toParentViewController: nil)
        addChildViewController(newViewController)
        
        oldViewController?.removeFromParentViewController()
        newViewController.didMove(toParentViewController: self)
    
        newViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        view.isAccessibilityElement = false
    
        oldViewController?.view.removeFromSuperview()
        containerView.addSubview(newViewController.view)
    
        let margins = containerView.safeAreaLayoutGuide
        let leading = newViewController.view.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
        let trailing = newViewController.view.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
        let top = newViewController.view.topAnchor.constraint(equalTo: margins.topAnchor)
        let bottom = newViewController.view.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
    
        leading.isActive = true
        trailing.isActive = true
        top.isActive = true
        bottom.isActive = true

        newViewController.view.updateConstraintsIfNeeded()
    }
    
    @IBAction func didTapSignMethodButton(sender: UIButton) {
        let id = TokenFlowMethodButtonID(rawValue: sender.accessibilityIdentifier ?? String())!
        DefaultsHelper.signMethod = id.rawValue
        if !sender.isSelected && !isSwitchingBlockedByTransition {
            selectButton(buttonID: id)
            changeTokenFlowMethod(newSignMethod: id)
        }
    }
    
    func selectButton(buttonID: TokenFlowMethodButtonID) {
        tokenFlowMethodButtons.forEach {
            let darkColor = UIColor.moppTitle
            let lightColor = UIColor.white
            let id = TokenFlowMethodButtonID(rawValue: $0.accessibilityIdentifier ?? String())!
            if id == buttonID {
                // set selected state
                $0.backgroundColor = darkColor
                $0.setTitleColor(lightColor, for: .normal)
                $0.setTitleColor(lightColor, for: .selected)
                $0.setTitleColor(lightColor, for: .highlighted)
                $0.titleLabel?.font = UIFont(name: MoppFontName.allCapsBold.rawValue, size: 17.0)
                $0.isSelected = true
            } else {
                // set unselected state
                $0.backgroundColor = lightColor
                $0.setTitleColor(darkColor, for: .normal)
                $0.setTitleColor(darkColor, for: .selected)
                $0.setTitleColor(darkColor, for: .highlighted)
                $0.titleLabel?.font = UIFont(name: MoppFontName.allCapsRegular.rawValue, size: 17.0)
                $0.isSelected = false
            }
        }
    }
}

extension TokenFlowSelectionViewController : IdCardSignViewKeyboardDelegate {
    func idCardPINKeyboardWillAppear() {
        if DeviceType.IS_IPHONE_5 {
            self.centerViewCenterCSTR.priority = UILayoutPriority(rawValue: 700)
            self.centerViewKeyboardCSTR.priority = UILayoutPriority(rawValue: 750)
            UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
            }) {_ in }
        }
    }
    
    func idCardPINKeyboardWillDisappear() {
        if DeviceType.IS_IPHONE_5 {
            self.centerViewCenterCSTR.priority = UILayoutPriority(rawValue: 750)
            self.centerViewKeyboardCSTR.priority = UILayoutPriority(rawValue: 700)
            UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
            }) {_ in }
        }
    }
}

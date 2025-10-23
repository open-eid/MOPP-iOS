//
//  TokenFlowSelectionViewController.swift
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

class TokenFlowSelectionViewController : MoppViewController {
    @IBOutlet weak var centerViewCenterCSTR: NSLayoutConstraint!
    @IBOutlet weak var centerViewOutofscreenCSTR: NSLayoutConstraint!
    @IBOutlet weak var centerViewKeyboardCSTR: NSLayoutConstraint!
    @IBOutlet var centerLandscapeCSTR: NSLayoutConstraint!
    @IBOutlet var tokenFlowMethodButtons: [UIButton]!
    @IBOutlet weak var tokenFlowView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var tokenNavbarView: UIView!
    @IBOutlet weak var tokenNavbar: UIView!
    @IBOutlet weak var mobileIDButton: ScaledButton!
    @IBOutlet weak var smartIDButton: ScaledButton!
    @IBOutlet weak var idCardButton: ScaledButton!
    @IBOutlet weak var nfcButton: ScaledButton!

    @IBOutlet weak var tokenViewContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tokenFlowViewLeadingCSTR: NSLayoutConstraint!
    @IBOutlet weak var tokenFlowViewTrailingCSTR: NSLayoutConstraint!
    @IBOutlet weak var tokenFlowViewHeightCSTR: NSLayoutConstraint!
    @IBOutlet weak var containerViewHeightCSTR: NSLayoutConstraint!
    @IBOutlet weak var tokenFlowViewCenterXCSTR: NSLayoutConstraint!
    @IBOutlet weak var tokenFlowViewCenterYCSTR: NSLayoutConstraint!
    
    
    var isFlowForDecrypting = false
    weak var mobileIdEditViewControllerDelegate: MobileIDEditViewControllerDelegate!
    weak var smartIdEditViewControllerDelegate: SmartIDEditViewControllerDelegate!
    weak var idCardDecryptViewControllerDelegate: IdCardDecryptViewControllerDelegate?
    weak var nfcEditViewControllerDelegate: NFCEditViewControllerDelegate!

    var containerPath: String!
    var addressees = [Addressee]()

    var isSwitchingBlockedByTransition: Bool = false
    
    var viewAccessibilityElements: [UIView] = []
    
    var deviceOrientation: UIDeviceOrientation = .portrait
    var topConstraintKeyboardShown = -56
    var mainViewHeight = CGFloat(0)
    
    var tokenFlowViewCenterXAnchor: NSLayoutConstraint? = nil
    var tokenFlowViewCenterYAnchor: NSLayoutConstraint? = nil
    var tokenFlowViewTopAnchor: NSLayoutConstraint? = nil
    var tokenFlowViewBottomAnchor: NSLayoutConstraint? = nil
    
    enum TokenFlowMethodButtonID: String {
        case mobileID
        case smartID
        case idCard
        case nfc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeButtonTitles()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let signMethod = TokenFlowMethodButtonID(rawValue: DefaultsHelper.signMethod) ?? .mobileID
        if isFlowForDecrypting {
            tokenNavbarView.isHidden = true
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
        
        handleConstraintInLandscape()
        
        deviceOrientation = UIDevice.current.orientation
        
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: {
            self.centerViewCenterCSTR.priority = .defaultHigh
            self.centerViewOutofscreenCSTR.priority = .defaultLow
            self.view.layoutIfNeeded()
        }) { _ in
            
        }

        tokenFlowViewCenterXAnchor = tokenFlowView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        tokenFlowViewCenterYAnchor = tokenFlowView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        
        tokenFlowViewTopAnchor = tokenFlowView.topAnchor.constraint(equalTo: view.topAnchor, constant: 25)
        tokenFlowViewBottomAnchor = tokenFlowView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 25)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        handleConstraintInLandscape()
    }
    
    func localizeButtonTitles() {
        tokenFlowMethodButtons.forEach {
            let id = TokenFlowMethodButtonID(rawValue: $0.accessibilityIdentifier!)!
            switch id {
            case .idCard:
                $0.setTitle(L(.signTitleIdCard))
                idCardButton.accessibilityLabel = setTabAccessibilityLabel(isTabSelected: false, tabName: L(.signTitleIdCard), positionInRow: "3", viewCount: "4")
                idCardButton.accessibilityUserInputLabels = [L(.voiceControlIdCard)]
                idCardButton.adjustedFont()
            case .mobileID:
                $0.setTitle(L(.signTitleMobileId))
                mobileIDButton.accessibilityLabel = setTabAccessibilityLabel(isTabSelected: false, tabName: L(.signTitleMobileId), positionInRow: "1", viewCount: "4")
                mobileIDButton.accessibilityUserInputLabels = [L(.voiceControlMobileId)]
                mobileIDButton.adjustedFont()
            case .smartID:
                $0.setTitle(L(.signTitleSmartId))
                smartIDButton.accessibilityLabel = setTabAccessibilityLabel(isTabSelected: false, tabName: L(.signTitleSmartId), positionInRow: "2", viewCount: "4")
                smartIDButton.accessibilityUserInputLabels = [L(.voiceControlSmartId)]
                smartIDButton.adjustedFont()
            case .nfc:
                $0.setTitle(L(.signTitleNFC))
                nfcButton.accessibilityLabel = setTabAccessibilityLabel(isTabSelected: false, tabName: L(.signTitleNFC), positionInRow: "4", viewCount: "4")
                nfcButton.accessibilityUserInputLabels = [L(.signTitleNFC)]
                nfcButton.adjustedFont()
            }
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        deviceOrientation = UIDevice.current.orientation
        
        let signMethod = DefaultsHelper.signMethod
        guard let newSignMethod = TokenFlowMethodButtonID(rawValue: signMethod) else { return }
        setConstraints(newViewController: self, containerView: containerView, newSignMethod: newSignMethod)
    }
    
    // Hide token flow methods so that small screens can enter text to textfields when in landscape orientation
    override func keyboardWillShow(notification: NSNotification) {
        if deviceOrientation == .landscapeLeft || deviceOrientation == .landscapeRight || deviceOrientation == .faceUp {
            handleLandscapeKeyboard(hideTokenNavbar: true, topConstraintConstant: CGFloat(topConstraintKeyboardShown))
        }
    }
    
    override func keyboardWillHide(notification: NSNotification) {
        handleLandscapeKeyboard(hideTokenNavbar: isFlowForDecrypting, topConstraintConstant: 0)
    }
    
    private func handleLandscapeKeyboard(hideTokenNavbar: Bool, topConstraintConstant: CGFloat) {
        tokenNavbarView.isHidden = hideTokenNavbar
        tokenViewContainerTopConstraint.constant = topConstraintConstant
        self.view.setNeedsUpdateConstraints()
        self.view.layoutIfNeeded()
    }
}

extension TokenFlowSelectionViewController {
    func changeTokenFlowMethod(newSignMethod: TokenFlowMethodButtonID) {
        let oldViewController = children.first
        let newViewController: MoppViewController!
        selectButton(buttonID: newSignMethod)
        switch newSignMethod {
        case .idCard:
            let idCardSignVC = UIStoryboard.tokenFlow.instantiateViewController(of: IdCardViewController.self)
            idCardSignVC.containerPath = containerPath
            idCardSignVC.addressees = addressees
            centerLandscapeCSTR.isActive = false
            if isFlowForDecrypting {
                idCardSignVC.isActionDecryption = true
                idCardSignVC.decryptDelegate = idCardDecryptViewControllerDelegate
            }
            idCardSignVC.keyboardDelegate = self
            newViewController = idCardSignVC
            viewAccessibilityElements = [idCardButton, containerView, mobileIDButton, smartIDButton, nfcButton, containerView]
        case .nfc:
            let nfcSignVC = UIStoryboard.tokenFlow.instantiateViewController(of: NFCEditViewController.self)
            centerLandscapeCSTR.isActive = false
            nfcSignVC.delegate = nfcEditViewControllerDelegate
            newViewController = nfcSignVC
            viewAccessibilityElements = [nfcButton, containerView, idCardButton, mobileIDButton, smartIDButton, containerView]
        case .mobileID:
            let mobileIdEditVC = UIStoryboard.tokenFlow.instantiateViewController(of: MobileIDEditViewController.self)
            handleConstraintInLandscape()
            mobileIdEditVC.delegate = mobileIdEditViewControllerDelegate
            newViewController = mobileIdEditVC
            viewAccessibilityElements = [mobileIDButton, containerView, smartIDButton, idCardButton, nfcButton, containerView]
        case .smartID:
            let smartIdEditVC = UIStoryboard.tokenFlow.instantiateViewController(of: SmartIDEditViewController.self)
            handleConstraintInLandscape()
            smartIdEditVC.delegate = smartIdEditViewControllerDelegate
            newViewController = smartIdEditVC
            viewAccessibilityElements = [smartIDButton, containerView, idCardButton, mobileIDButton, smartIDButton, nfcButton, containerView]
        }
        
        if UIAccessibility.isVoiceOverRunning {
            self.view.accessibilityElements = viewAccessibilityElements
            newViewController.accessibilityElements = viewAccessibilityElements
        }
        
        oldViewController?.willMove(toParent: nil)
        addChild(newViewController)
        
        oldViewController?.removeFromParent()
        newViewController.didMove(toParent: self)
    
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
        
        setConstraints(newViewController: newViewController, containerView: containerView, newSignMethod: newSignMethod)
        
        if newSignMethod == .idCard {
            containerView.backgroundColor = .clear
        }
    }
    
    override func viewDidLayoutSubviews() {
        if let parentView = tokenFlowView.superview {
            mainViewHeight = parentView.bounds.height
        }

        let signMethod = DefaultsHelper.signMethod
        guard let newSignMethod = TokenFlowMethodButtonID(rawValue: signMethod) else { return }
        setConstraints(newViewController: self, containerView: containerView, newSignMethod: newSignMethod)
    }
    
    private func setConstraints(newViewController: UIViewController?, containerView: UIView, newSignMethod: TokenFlowMethodButtonID?) {
        let currentOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait

        if currentOrientation.isLandscape {
            tokenFlowViewLeadingCSTR.constant = 48
            tokenFlowViewTrailingCSTR.constant = 48

            tokenFlowViewTopAnchor?.isActive = true
            tokenFlowViewBottomAnchor?.isActive = true

            if UIDevice.current.userInterfaceIdiom == .pad {
                tokenFlowViewHeightCSTR.constant = 500
            } else {
                tokenFlowViewHeightCSTR.constant = mainViewHeight - 50
            }
            containerViewHeightCSTR.constant = tokenFlowViewHeightCSTR.constant - tokenNavbarView.frame.height
            centerLandscapeCSTR.constant = tokenFlowViewHeightCSTR.constant * centerLandscapeCSTR.multiplier
        } else if currentOrientation.isPortrait {
            tokenFlowViewLeadingCSTR.constant = 16
            tokenFlowViewTrailingCSTR.constant = 16

            tokenFlowViewTopAnchor?.isActive = false
            tokenFlowViewBottomAnchor?.isActive = false

            tokenFlowViewCenterXCSTR.isActive = true
            tokenFlowViewCenterYCSTR.isActive = true

            tokenFlowViewHeightCSTR.constant = 475
            containerViewHeightCSTR.constant = tokenFlowViewHeightCSTR.constant - tokenNavbarView.frame.height
            centerLandscapeCSTR.constant = tokenFlowViewHeightCSTR.constant * centerLandscapeCSTR.multiplier
        }
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
                $0.isSelected = true
            } else {
                // set unselected state
                $0.backgroundColor = lightColor
                $0.setTitleColor(darkColor, for: .normal)
                $0.setTitleColor(darkColor, for: .selected)
                $0.setTitleColor(darkColor, for: .highlighted)
                $0.isSelected = false
            }
        }
    }
    
    func handleConstraintInLandscape() {
        if isDeviceOrientationLandscape() {
            centerLandscapeCSTR.isActive = true
        } else {
            centerLandscapeCSTR.isActive = false
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

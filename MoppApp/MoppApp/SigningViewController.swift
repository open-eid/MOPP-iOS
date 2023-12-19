//
//  SigningViewController.swift
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

import Foundation

class SigningViewController : MoppViewController {
    
    @IBOutlet var containerView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var importButton: UIButton!
    @IBOutlet weak var recentDocumentsButton: ScaledButton!
    @IBOutlet weak var menuButton: BarButton!
    
    enum Section {
        case fileImport
    }

    var sections: [Section] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = L(LocKey.signatureViewBeginLabel)
        importButton.localizedTitle = LocKey.signatureViewBeginButton
        recentDocumentsButton.localizedTitle = LocKey.recentContainersButton
        menuButton.isAccessibilityElement = true
        menuButton.accessibilityLabel = L(LocKey.menuButton)
        
        addInvisibleBottomLabelTo(containerView)
        
        titleLabel.isAccessibilityElement = false
        importButton.accessibilityLabel = L(.signatureViewBeginLabelAccessibility)
        importButton.accessibilityUserInputLabels = [L(.voiceControlChooseFile)]
        recentDocumentsButton.accessibilityLabel = L(.recentContainersButton).lowercased()
        recentDocumentsButton.accessibilityUserInputLabels = [L(.recentContainersButton)]
        
        recentDocumentsButton.layer.borderWidth = 2
        recentDocumentsButton.layer.borderColor = UIColor.moppBase.cgColor
        
        UIAccessibility.post(notification: .screenChanged, argument: importButton)
        
        guard let importUIButton = importButton, let recentDocumentsUIButton = recentDocumentsButton, let bottomUIButtons = LandingViewController.shared.buttonsStackView, let menuUIButton = menuButton else {
            printLog("Unable to get importButton, recentDocumentsButton, LandingViewController buttonsStackView or menuButton")
            return
        }
        
        self.accessibilityElements = [importUIButton, recentDocumentsUIButton, bottomUIButtons, menuUIButton, importUIButton]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LandingViewController.shared.isAlreadyInMainPage = true
        LandingViewController.shared.presentButtons([.signTab, .cryptoTab, .myeIDTab])
    }
    
    @IBAction func menuActivationSelector() {
        let invisibleLabel = getInvisibleLabelInView(MoppApp.instance.rootViewController?.view, accessibilityIdentifier: invisibleElementAccessibilityIdentifier)
        invisibleLabel?.isHidden = true
        let menuViewController = UIStoryboard.menu.instantiateInitialViewController()!
            menuViewController.modalPresentationStyle = .overFullScreen
        MoppApp.instance.rootViewController?.present(menuViewController, animated: true, completion: nil)
    }
    
    @IBAction func importFilesAction() {
        NotificationCenter.default.post(
            name: .startImportingFilesWithDocumentPickerNotificationName,
            object: nil,
            userInfo: [kKeyFileImportIntent: MoppApp.FileImportIntent.openOrCreate, kKeyContainerType: MoppApp.ContainerType.asic])
    }
    
    @IBAction func openRecentDocuments(_ sender: ScaledButton) {
        DispatchQueue.main.async(execute: {
            guard let recentContainersViewController = UIStoryboard.recentContainers.instantiateInitialViewController() else { return }
            recentContainersViewController.modalPresentationStyle = .fullScreen
            MoppApp.instance.rootViewController?.present(recentContainersViewController, animated: true, completion: nil)
        })
    }
}

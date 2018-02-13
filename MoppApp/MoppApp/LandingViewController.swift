//
//  LandingViewController.swift
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
protocol LandingViewControllerTabButtonsDelegate: class {
    func landingViewControllerTabButtonTapped(tabButtonId: LandingViewController.TabButtonId, sender: UIView)
}

class LandingViewController : UIViewController, NativeShare, ContainerActions
{
    weak var tabButtonsDelegate: LandingViewControllerTabButtonsDelegate? = nil
    var fileImportIntent: MoppApp.FileImportIntent!

    var importProgressViewController: FileImportProgressViewController = {
        let importProgressViewController = UIStoryboard.landing.instantiateViewController(with: FileImportProgressViewController.self)
            importProgressViewController.modalPresentationStyle = .overFullScreen
        return importProgressViewController
    }()

    var documentPicker: UIDocumentPickerViewController = {
        let allowedDocumentTypes = ["public.content", "public.data", "public.image", "public.movie", "public.audio", "public.item"]
        let documentPicker = UIDocumentPickerViewController(documentTypes: allowedDocumentTypes, in: .import)
            documentPicker.modalPresentationStyle = .overCurrentContext
            documentPicker.allowsMultipleSelection = true
        return documentPicker
    }()

    @IBOutlet weak var containerViewBottomCSTR: NSLayoutConstraint!
    @IBOutlet weak var containerViewButtonBarCSTR: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet var buttonsCollection: [TabButton]!
    @IBOutlet weak var buttonBarView: UIView!
    @IBOutlet weak var buttonsStackView: UIStackView!

    @IBAction func selectTabAction(sender: UIButton)
     {
        let tabId = TabButtonId(rawValue: sender.superview!.accessibilityIdentifier!)!
        
        selectTabButton(tabId)
        selectedTab = tabId
    }

    enum TabButtonId: String {
        case signTab
        case cryptoTab
        case myeIDTab
        case shareButton
        case signButton
        case encryptButton
    }

    var selectedTab: TabButtonId = .signTab {
        didSet {
            for (id, vc) in viewControllersToTabs {
                vc.view.isHidden = id != selectedTab
            }
            selectTab(with: selectedTab)
        }
    }
    var viewControllers: [UIViewController] = []
    var viewControllersToTabs: [TabButtonId: UIViewController] = [:]
    static private(set) var shared: LandingViewController!

    func selectTab(with tabButtonId: TabButtonId) {
        buttonsCollection.forEach {
            $0.setSelected(TabButtonId(rawValue: $0.accessibilityIdentifier!)! == tabButtonId)
        }
    }

    func configureConstraints(for targetView: UIView) {
        let margins = self.containerView.safeAreaLayoutGuide

        targetView.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        targetView.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        targetView.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        targetView.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
        targetView.translatesAutoresizingMaskIntoConstraints = false
        targetView.updateConstraints()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        LandingViewController.shared = self
        
        viewControllers.append(UIStoryboard.signing.instantiateInitialViewController()!)
        viewControllers.append(UIStoryboard.crypto.instantiateInitialViewController()!)
        viewControllers.append(UIStoryboard.myEID.instantiateInitialViewController()!)
        
        viewControllersToTabs[.signTab] = viewControllers[0]
        viewControllersToTabs[.cryptoTab] = viewControllers[1]
        viewControllersToTabs[.myeIDTab] = viewControllers[2]
        
        viewControllers.forEach { viewController in
            viewController.view.frame = view.bounds
            containerView.addSubview(viewController.view)
            viewController.view.frame = containerView.bounds
            configureConstraints(for: viewController.view)
            containerView.updateConstraints()
        }
        
        selectedTab = .signTab
        
        buttonsCollection.forEach {
            if $0.kind == .button {
                $0.button.addTarget(self, action: #selector(tabButtonTapAction), for: .touchUpInside)
            }
        }
        
        presentButtons([.signTab, .cryptoTab, .myeIDTab])
        selectTabButton(.signTab)

        NotificationCenter.default.addObserver(self, selector: #selector(receiveErrorNotification), name: .errorNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveStartImportingFilesWithDocumentPickerNotification), name: .startImportingFilesWithDocumentPickerNotificationName, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        buttonsCollection.forEach {
            if $0.kind == .button {
                $0.button.removeTarget(self, action: #selector(tabButtonTapAction), for: .touchUpInside)
            }
        }
    }

    @objc func tabButtonTapAction(sender: UIButton) {
        let tabButton = buttonsCollection.first { $0.button == sender }!
        let buttonId = TabButtonId(rawValue: tabButton.accessibilityIdentifier!)!
        tabButtonsDelegate?.landingViewControllerTabButtonTapped(tabButtonId: buttonId, sender: sender)
    }

    func setupTab(for controller: UIViewController, title: String, image imageName: String, selectedImage selectedImageName: String) {
        controller.title = title
        let selectedImage = UIImage(named: imageName)
        let image: UIImage? = selectedImage?.applyingAlpha(UIColor.moppUnselectedTabBarItemAlpha).withRenderingMode(.alwaysOriginal)
        controller.tabBarItem.image = image
        controller.tabBarItem.selectedImage = selectedImage
    }

    @objc func receiveErrorNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let error = userInfo[kErrorKey] as? NSError
        var errorMessage = error?.userInfo[NSLocalizedDescriptionKey] as? String ??
            userInfo[kErrorMessage] as? String
        
        if errorMessage == "USER_CANCEL" {
            errorMessage = MoppLib_LocalizedString("digidoc-service-status-request-user-cancel")
        }
        else if errorMessage == "EXPIRED_TRANSACTION" {
            errorMessage = MoppLib_LocalizedString("digidoc-service-status-request-expired-transaction")
        }
        
        let alert = UIAlertController(
            title: L(.errorAlertTitleGeneral),
            message: errorMessage,
            preferredStyle: .alert)
        
        presentedViewController?.dismiss(animated: true, completion: nil)
        alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    @objc func receiveStartImportingFilesWithDocumentPickerNotification(_ notification: Notification) {
        fileImportIntent = notification.userInfo![kKeyFileImportIntent] as! MoppApp.FileImportIntent
        documentPicker.delegate = self
        present(documentPicker, animated: false, completion: nil)
    }


}

extension LandingViewController : UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        importFiles(with: urls)
    }
}

extension LandingViewController {
    func presentButtons(_ buttonIDs: [TabButtonId]) {
        
        buttonBarView.isHidden = buttonIDs.isEmpty
        if buttonIDs.isEmpty {
            containerViewBottomCSTR.priority = .defaultHigh
            containerViewButtonBarCSTR.priority = .defaultLow
        } else {
            containerViewBottomCSTR.priority = .defaultLow
            containerViewButtonBarCSTR.priority = .defaultHigh
        }
        
        view.layoutIfNeeded()
        
        var visibleViews: [UIView] = []
        buttonsCollection.forEach { button in
            if buttonIDs.first(where: { TabButtonId(rawValue: button.accessibilityIdentifier!)! == $0 }) != nil {
                visibleViews.append(button)
            }
            buttonsStackView.removeArrangedSubview(button)
            button.removeFromSuperview()
        }

        buttonIDs.forEach { buttonID in
            let button = visibleViews.first(where: { buttonID == TabButtonId(rawValue: $0.accessibilityIdentifier!)! })!
            buttonsStackView.addArrangedSubview(button)
        }
    }
    
    func selectTabButton(_ button: TabButtonId) {
        for b in buttonsCollection {
            if b.kind == .tab {
                let id = TabButtonId(rawValue: b.accessibilityIdentifier!)!
                b.setSelected(id == button)
            }
        }
    }
}

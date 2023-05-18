//
//  LandingViewController.swift
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
protocol LandingViewControllerTabButtonsDelegate: AnyObject {
    func landingViewControllerTabButtonTapped(tabButtonId: LandingViewController.TabButtonId, sender: UIView)
}

class LandingViewController : UIViewController, NativeShare, ContainerActions
{
    weak var tabButtonsDelegate: LandingViewControllerTabButtonsDelegate? = nil
    var fileImportIntent: MoppApp.FileImportIntent!
    var containerType: MoppApp.ContainerType!
    var isAlreadyInMainPage: Bool = false
    var importProgressViewController: FileImportProgressViewController = {
        let importProgressViewController = UIStoryboard.landing.instantiateViewController(of: FileImportProgressViewController.self)
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
        case myeIDTab
        case cryptoTab
        case shareButton
        case signButton
        case encryptButton
        case decryptButton
        case confirmButton
    }

    var selectedTab: TabButtonId = .signTab {
        willSet {
            if children.first != nil && selectedTab == newValue {
                return
            }
            changeTabViewController(with: newValue)
            selectTab(with: newValue)
        }
    }

    func createSigningViewController() -> UIViewController {
        return UIStoryboard.signing.instantiateInitialViewController()!
    }
        
    func createMyeIDViewController() -> UIViewController {
        return UIStoryboard.myEID.instantiateInitialViewController()!
    }
    
    func createCryptoViewController() -> UIViewController {
        return UIStoryboard.crypto.instantiateInitialViewController()!
    }
    
    func createViewController(for tab:TabButtonId) -> UIViewController {
        switch tab {
        case .signTab:
            return createSigningViewController()
        case .myeIDTab:
            return createMyeIDViewController()
        case .cryptoTab:
            return createCryptoViewController()
        default:
            break
        }
        return UIViewController()
    }
    
    static private(set) var shared: LandingViewController!

    func selectTab(with tabButtonId: TabButtonId) {
        buttonsCollection.forEach {
            $0.setSelected(TabButtonId(rawValue: $0.accessibilityIdentifier!)! == tabButtonId)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        LandingViewController.shared = self
        
        buttonsStackView.isAccessibilityElement = false

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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didFinishAnnouncement(_:)),
            name: UIAccessibility.announcementDidFinishNotification,
            object: nil)
    }

    @objc func didFinishAnnouncement(_ notification: Notification) {
        let announcementValue: String? = notification.userInfo?[UIAccessibility.announcementStringValueUserInfoKey] as? String
        let isAnnouncementSuccessful: Bool? = notification.userInfo?[UIAccessibility.announcementWasSuccessfulUserInfoKey] as? Bool

        guard let isSuccessful = isAnnouncementSuccessful else {
            return
        }

        if !isSuccessful {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: announcementValue)
        } else if announcementValue == L(.dataFileAdded) || announcementValue == L(.dataFilesAdded) {
            UIAccessibility.post(notification: .layoutChanged, argument: navigationItem.leftBarButtonItem)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        buttonsCollection.forEach {
            if $0.kind == .button {
                $0.button.removeTarget(self, action: #selector(tabButtonTapAction), for: .touchUpInside)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedTab = .signTab
    }

    func changeTabViewController(with buttonID: TabButtonId) {
        let oldViewController = children.first
        let newViewController = createViewController(for: buttonID)
        
        oldViewController?.willMove(toParent: nil)
        addChild(newViewController)
        
        oldViewController?.removeFromParent()
        newViewController.didMove(toParent: self)
    
        newViewController.view.translatesAutoresizingMaskIntoConstraints = false
    
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

    func viewController(for tab: TabButtonId) -> UIViewController {
        selectedTab = tab
        return children.first!
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
        guard let strongErrorMessage = errorMessage else { return }
        errorMessage = MoppLib_LocalizedString(strongErrorMessage)
        let alert = UIAlertController(
            title: L(.errorAlertTitleGeneral),
            message: errorMessage,
            preferredStyle: .alert)
        
        presentedViewController?.dismiss(animated: false, completion: nil)
        alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    @objc func receiveStartImportingFilesWithDocumentPickerNotification(_ notification: Notification) {
        fileImportIntent = notification.userInfo![kKeyFileImportIntent] as? MoppApp.FileImportIntent
        containerType = notification.userInfo![kKeyContainerType] as? MoppApp.ContainerType
        documentPicker.delegate = self
        present(documentPicker, animated: false, completion: nil)
    }


}

extension LandingViewController : UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        var isEmptyFileImported: Bool = false
        for url in urls {
            if MoppFileManager.isFileEmpty(fileUrl: url) {
                isEmptyFileImported = true
                break
            }
        }
        importFiles(with: urls, cleanup: true, isEmptyFileImported: isEmptyFileImported)
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
        
        visibleViews.forEach { view in
            switch view.accessibilityIdentifier {
            case "signTab":
                view.accessibilityLabel = selectedTab == .signTab ? setTabAccessibilityLabel(isTabSelected: true, tabName: L(.tabSignature), positionInRow: "1", viewCount: String(visibleViews.count)) : setTabAccessibilityLabel(isTabSelected: false, tabName: L(.tabSignature), positionInRow: "1", viewCount: String(visibleViews.count))
                view.accessibilityUserInputLabels = [L(.voiceControlTabSignature)]
                break
            case "cryptoTab":
                view.accessibilityLabel = selectedTab == .cryptoTab ? setTabAccessibilityLabel(isTabSelected: true, tabName: L(.tabCrypto), positionInRow: "2", viewCount: String(visibleViews.count)) : setTabAccessibilityLabel(isTabSelected: false, tabName: L(.tabCrypto), positionInRow: "2", viewCount: String(visibleViews.count))
                view.accessibilityUserInputLabels = [L(.voiceControlTabCrypto)]
                break
            case "myeIDTab":
                view.accessibilityLabel = selectedTab == .myeIDTab ? setTabAccessibilityLabel(isTabSelected: true, tabName: L(.myEidInfoMyEidAccessibility), positionInRow: "3", viewCount: String(visibleViews.count)) : setTabAccessibilityLabel(isTabSelected: false, tabName: L(.myEidInfoMyEidAccessibility), positionInRow: "3", viewCount: String(visibleViews.count))
                view.accessibilityUserInputLabels = [L(.voiceControlTabMyEid)]
                break
            case "shareButton":
                view.accessibilityLabel = setTabAccessibilityLabel(isTabSelected: false, tabName: L(.tabShareButtonAccessibility), positionInRow: "1", viewCount: String(visibleViews.count))
                view.accessibilityTraits = UIAccessibilityTraits.button
                view.accessibilityUserInputLabels = [L(.voiceControlTabShare)]
                break
            case "signButton":
                if buttonIDs.contains(TabButtonId.signButton) && buttonIDs.count == 1 {
                    view.accessibilityLabel = L(.tabSignButton)
                } else {
                    view.accessibilityLabel = setTabAccessibilityLabel(isTabSelected: false, tabName: L(.tabSignButton), positionInRow: "2", viewCount: String(visibleViews.count))
                }
                view.accessibilityTraits = UIAccessibilityTraits.button
                view.accessibilityUserInputLabels = [L(.voiceControlTabSign)]
                break
            case "encryptButton":
                view.accessibilityLabel = L(.tabEncryptButtonAccessibility)
                view.accessibilityTraits = UIAccessibilityTraits.button
                break
            case "decryptButton":
                if buttonIDs.contains(TabButtonId.decryptButton) && buttonIDs.contains(TabButtonId.shareButton) {
                    view.accessibilityLabel = setTabAccessibilityLabel(isTabSelected: false, tabName: L(.tabDecryptButton), positionInRow: "2", viewCount: String(visibleViews.count))
                } else {
                    view.accessibilityLabel = L(.tabDecryptButton)
                }
                view.accessibilityTraits = UIAccessibilityTraits.button
                break
            case "confirmButton":
                view.accessibilityLabel = L(.tabConfirmButton)
                view.accessibilityTraits = UIAccessibilityTraits.button
                break
            default:
                break
            }
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

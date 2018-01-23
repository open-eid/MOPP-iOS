//
//  LandingTabBarController.swift
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
protocol LandingTabBarControllerTabButtonsDelegate {
    func landingTabBarControllerTabButtonTapped(tabButtonId: LandingTabBarController.TabButtonId)
}

class LandingTabBarController : UIViewController
{
    var tabButtonsDelegate: LandingTabBarControllerTabButtonsDelegate? = nil

    @IBOutlet weak var containerViewBottomCSTR: NSLayoutConstraint!
    @IBOutlet weak var containerViewButtonBarCSTR: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet var buttonsCollection: [TabButton]!
    @IBOutlet weak var buttonBarView: UIView!

    @IBAction func selectTab(sender: UIButton)
     {
        let tabId = TabButtonId(rawValue: sender.superview!.accessibilityIdentifier!)!
        selectTabButton(tabId)
        
        if tabId == .signTab {
            selectedIndex = 0
        }
        else if tabId == .cryptoTab {
            selectedIndex = 1
        }
        else if tabId == .myeIDTab {
            selectedIndex = 2
        }
    }

    enum TabButtonId: String {
        case signTab
        case cryptoTab
        case myeIDTab
        case shareButton
        case signButton
        case encryptButton
    }

    var selectedIndex = 0 {
        didSet {
            for i in 0..<viewControllers.count {
                viewControllers[i].view.isHidden = selectedIndex != i
            }
        }
    }
    var viewControllers: [UIViewController] = []
    static private(set) var shared: LandingTabBarController!

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
        LandingTabBarController.shared = self
        
        viewControllers.append(UIStoryboard.signing.instantiateInitialViewController()!)
        viewControllers.append(UIStoryboard.crypto.instantiateInitialViewController()!)
        viewControllers.append(UIStoryboard.myEID.instantiateInitialViewController()!)
        
        viewControllers.forEach { viewController in
            viewController.view.frame = view.bounds
            containerView.addSubview(viewController.view)
            viewController.view.frame = containerView.bounds
            configureConstraints(for: viewController.view)
            containerView.updateConstraints()
        }
        
        selectedIndex = 0
        
        buttonsCollection.forEach {
            if $0.kind == .button {
                $0.button.addTarget(self, action: #selector(tabButtonTapAction), for: .touchUpInside)
            }
        }
        
        presentButtons([.signTab, .cryptoTab, .myeIDTab])
        selectTabButton(.signTab)

        NotificationCenter.default.addObserver(self, selector: #selector(receiveErrorNotification), name: .errorNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveOpenContainerNotification), name: .openContainerNotificationName, object: nil)
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
        tabButtonsDelegate?.landingTabBarControllerTabButtonTapped(tabButtonId: buttonId)
    }

    func setupTab(for controller: UIViewController, title: String, image imageName: String, selectedImage selectedImageName: String) {
        controller.title = title
        let selectedImage = UIImage(named: imageName)
        let image: UIImage? = selectedImage?.applyingAlpha(UIColor.moppUnselectedTabBarItemAlpha).withRenderingMode(.alwaysOriginal)
        controller.tabBarItem.image = image
        controller.tabBarItem.selectedImage = selectedImage
    }

    @objc func receiveOpenContainerNotification(_ notification: Notification) {
        guard let container = notification.userInfo?[kKeyContainer] as? MoppLibContainer else {
            return
        }
        
        let isCreated = (notification.userInfo?["isCreated"] as? Bool) ?? false
        
        navigationController?.dismiss(animated: true, completion: nil)
        
        // Select signing tab
        selectedIndex = 0
        if let navigationController = viewControllers.first as? UINavigationController {
            if let signingViewController = navigationController.viewControllers.first as? SigningViewController {
                signingViewController.refresh()
            }
            let containerViewController = ContainerViewController.instantiate()
                containerViewController.containerPath = container.filePath
                containerViewController.isCreated = isCreated
            navigationController.pushViewController(containerViewController, animated: false)
        }
    }

    @objc func receiveErrorNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let error = userInfo[kErrorKey] as? NSError
        var errorMessage = error?.userInfo[NSLocalizedDescriptionKey] as? String ??
            userInfo[kErrorMessage] as? String
        
        if errorMessage == "USER_CANCEL" {
            errorMessage = L(.mobileIdUserCancelMessage)
        }
        
        let alert = UIAlertController(
            title: L(.errorAlertTitleGeneral),
            message: errorMessage,
            preferredStyle: .alert)
        
        presentedViewController?.dismiss(animated: true, completion: nil)
        alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))
        present(alert, animated: true)
    }

}

extension LandingTabBarController {
    func presentButtons(_ buttons: [TabButtonId]) {
        buttonBarView.isHidden = buttons.isEmpty
        if buttons.isEmpty {
            containerViewBottomCSTR.priority = .defaultHigh
            containerViewButtonBarCSTR.priority = .defaultLow
        } else {
            containerViewBottomCSTR.priority = .defaultLow
            containerViewButtonBarCSTR.priority = .defaultHigh
        }
        view.layoutIfNeeded()
        for b in buttons {
            self.buttonsCollection.first(where: { $0.accessibilityIdentifier == b.rawValue })?.isHidden = false
        }
        let buttonsToHide = self.buttonsCollection.filter {
            !buttons.contains(TabButtonId(rawValue: $0.accessibilityIdentifier!)!)
        }
        buttonsToHide.forEach {
            $0.isHidden = true
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

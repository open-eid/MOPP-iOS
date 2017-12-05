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

class LandingTabBarController : UITabBarController
{
    var currentMobileIDChallengeView: MobileIDChallengeViewController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.barTintColor = UIColor.white
        if let viewControllers = viewControllers {
            setupTab(for: viewControllers[0], title: L(LocKey.tabSignature), image: "IconSignature", selectedImage: "IconSignature")
            setupTab(for: viewControllers[1], title: L(LocKey.tabCrypto), image: "IconCrypto", selectedImage: "IconCryptoSelected")
            setupTab(for: viewControllers[2], title: L(LocKey.tabMyEid), image: "IconMyEID", selectedImage: "IconMyEIDSelected")
        }
        // [self setupTabFor:[self.viewControllers objectAtIndex:3] title:Localizations.TabSettings image:@"settingsNormal" selectedImage:@"settingsNormal_2"];
        NotificationCenter.default.addObserver(self, selector: #selector(receiveMobileCreateSignatureNotification), name: .createSignatureNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveErrorNotification), name: .errorNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveOpenContainerNotification), name: .openContainerNotificationName, object: nil)
    }

    func setupTab(for controller: UIViewController, title: String, image imageName: String, selectedImage selectedImageName: String) {
        controller.title = title
        let selectedImage = UIImage(named: imageName)
        let image: UIImage? = selectedImage?.applyingAlpha(UIColor.moppUnselectedTabBarItemAlpha).withRenderingMode(.alwaysOriginal)
        controller.tabBarItem.image = image
        controller.tabBarItem.selectedImage = selectedImage
    }

    @objc func receiveOpenContainerNotification(_ notification: Notification) {
        guard let container = notification.userInfo?[kKeyContainerNew] as? MoppLibContainer else {
            return
        }
        // Select signing tab
        selectedIndex = 0
        if let navigationController = viewControllers?.first as? UINavigationController {
            if let signingViewController = navigationController.viewControllers.first as? SigningViewController {
                signingViewController.refresh()
            }
            if let containerViewController = UIStoryboard.container.instantiateInitialViewController() as? ContainerViewController {
                containerViewController.container = container
                navigationController.pushViewController(containerViewController, animated: false)
            }
        }
    }

    @objc func receiveMobileCreateSignatureNotification(_ notification: Notification) {
    
        guard let response = notification.userInfo?[kCreateSignatureResponseKey] as? MoppLibMobileCreateSignatureResponse else {
            return
        }
        
        let mobileIDChallengeview = storyboard?.instantiateViewController(withIdentifier: "MobileIDChallengeView") as? MobileIDChallengeViewController
        
        currentMobileIDChallengeView = mobileIDChallengeview
        currentMobileIDChallengeView!.challengeID = response.challengeId!
        currentMobileIDChallengeView!.sessCode = "\(Int(response.sessCode))"
        currentMobileIDChallengeView!.modalPresentationStyle = .overCurrentContext
        currentMobileIDChallengeView!.view.alpha = 0.75
        present(currentMobileIDChallengeView!, animated: true)
    }

    @objc func receiveErrorNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let error = userInfo[kErrorKey] as? NSError else { return }
        let alert = UIAlertController(title: L(.errorAlertTitleGeneral), message: error.userInfo[NSLocalizedDescriptionKey] as? String, preferredStyle: .alert)
        currentMobileIDChallengeView?.dismiss(animated: true)
        alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))
        present(alert, animated: true)
    }

}

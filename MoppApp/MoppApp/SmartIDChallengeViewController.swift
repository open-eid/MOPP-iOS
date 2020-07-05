//
//  SmartIDChallengeViewController.swift
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

import SkSigningLib

private var kRequestTimeout: Double = 120.0


class SmartIDChallengeViewController : UIViewController {

    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var timeoutProgressView: UIProgressView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var helpLabel: UILabel!

    var currentProgress: Double = 0.0
    var sessionTimer: Timer?
    var pendingnotification = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = L(.smartIdChallengeTitle)
        helpLabel.text = nil

        NotificationCenter.default.addObserver(self, selector: #selector(receiveSelectAccountNotification), name: .selectSmartIDAccountNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveCreateSignatureNotification), name: .createSignatureNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveCreateSignatureStatus), name: .signatureAddedToContainerNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveErrorNotification), name: .errorNotificationName, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func receiveSelectAccountNotification(_ notification: Notification) {
        helpLabel.text = MoppLib_LocalizedString("digidoc-service-status-request-select-account")
    }

    @objc func receiveCreateSignatureNotification(_ notification: Notification) {
        guard let challengeID = notification.userInfo?[kKeySmartIDChallengeKey] as? String else {
            return
        }

        titleLabel.text = MoppLib_LocalizedString("digidoc-service-status-request-ok")
        helpLabel.text = L(.smartIdSignHelpTitle)
        codeLabel.text = L(.challengeCodeLabel, [challengeID])
        codeLabel.isHidden = false
        let challengeIdNumbers = Array<Character>(challengeID)
        codeLabel.accessibilityLabel = L(.challengeCodeLabel, ["\(challengeIdNumbers[0]), \(challengeIdNumbers[1]), \(challengeIdNumbers[2]), \(challengeIdNumbers[3])"])
        currentProgress = 0.0
        sessionTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateSessionProgress), userInfo: nil, repeats: true)

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { didAllow, error in
                    self.showNotification(challengeID: challengeID)
                }
            } else {
                self.showNotification(challengeID: challengeID)
            }
        }
    }

    @objc func receiveCreateSignatureStatus(_ notification: Notification) {
        self.titleLabel.text = MoppLib_LocalizedString("digidoc-service-status-request-signature")
        sessionTimer?.invalidate()
        NotificationCenter.default.post(name: .signatureCreatedFinishedNotificationName, object: nil)
        dismiss(animated: false)
    }

    @objc func receiveErrorNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let error = userInfo[kErrorKey] as? NSError
        let mobileIDErrorMessage = error?.userInfo[NSLocalizedDescriptionKey] as? MobileIDError
        let errorMessage = userInfo[kErrorMessage] as? String ?? MobileIDError.generalError.mobileIDErrorDescription ?? L(.genericErrorMessage)
        let message = SkSigningLib_LocalizedString(mobileIDErrorMessage?.mobileIDErrorDescription ?? errorMessage)
        self.dismiss(animated: false) {
            if var topViewController = UIApplication.shared.keyWindow?.rootViewController {
                while let currentViewController = topViewController.presentedViewController {
                    topViewController = currentViewController
                }

                let errorMessageNoLink = message.removeFirstLinkFromMessage()
                let alert = UIAlertController(title: L(.errorAlertTitleGeneral), message: errorMessageNoLink, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                if let linkInUrl = message.getFirstLinkInMessage() {
                    if let alertActionUrl = UIAlertAction().getLinkAlert(message: linkInUrl) {
                        alert.addAction(alertActionUrl)
                    }
                }

                topViewController.present(alert, animated: true, completion: nil)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        UIView.animate(withDuration: 0.35) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [pendingnotification])
        sessionTimer?.invalidate()
    }

    @objc func updateSessionProgress(_ timer: Timer) {
        if currentProgress < 1.0 {
            let step: Double = 1.0 / kRequestTimeout
            currentProgress = currentProgress + step
            timeoutProgressView.progress = Float(currentProgress)
        }
        else {
            timer.invalidate()
            dismiss(animated: false, completion: nil)
        }
    }

    private func showNotification(challengeID: String) {
        let content = UNMutableNotificationContent()
        content.title = "Smart-ID challenge"
        content.subtitle = challengeID
        content.sound = UNNotificationSound.default()
        pendingnotification = UUID().uuidString;
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: pendingnotification, content: content, trigger: nil))
    }
}

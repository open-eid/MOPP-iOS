/*
 * MoppApp - SmartIDChallengeViewController.swift
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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
    @IBOutlet weak var helpLabel: UILabel!

    var currentProgress: Double = 0.0
    var sessionTimer: Timer?
    var pendingnotification = ""
    var challengeCodeAccessibilityLabel = ""
    var isTimeoutProgressRead = false

    override func viewDidLoad() {
        super.viewDidLoad()
        helpLabel.text = L(.smartIdChallengeTitle)

        NotificationCenter.default.addObserver(self, selector: #selector(receiveSelectAccountNotification), name: .selectSmartIDAccountNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveCreateSignatureNotification), name: .createSignatureNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveCreateSignatureStatus), name: .signatureAddedToContainerNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveErrorNotification), name: .errorNotificationName, object: nil)
        
        if UIAccessibility.isVoiceOverRunning {
            NotificationCenter.default.addObserver(self, selector: #selector(handleAccessibility), name: UIApplication.didBecomeActiveNotification, object: nil)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didFinishAnnouncement(_:)),
                name: UIAccessibility.announcementDidFinishNotification,
                object: nil)
        }

        timeoutProgressView.isAccessibilityElement = false

        UIAccessibility.post(notification: .announcement, argument: timeoutProgressView.progress)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func receiveSelectAccountNotification(_ notification: Notification) {
        helpLabel.text = MoppLib_LocalizedString("smart-id-status-request-select-account")
        currentProgress = 0.0
        sessionTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateSessionProgress), userInfo: nil, repeats: true)
        if UIAccessibility.isVoiceOverRunning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let message: NSAttributedString = NSAttributedString(string: "\(L(.signingProgress)) \(String(Int(self.timeoutProgressView.progress))) %. \(self.helpLabel.text ?? "")", attributes: [.accessibilitySpeechQueueAnnouncement: false])
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        }
    }

    @objc func receiveCreateSignatureNotification(_ notification: Notification) {
        guard let challengeID = notification.userInfo?[kKeySmartIDChallengeKey] as? String else {
            return
        }

        helpLabel.text = L(.smartIdSignHelpTitle)
        codeLabel.text = challengeID
        codeLabel.isHidden = false
        let challengeIdNumbers = Array<Character>(challengeID)
        let challengeIdAccessibilityLabel: String = "\((L(LocKey.challengeCodeLabelAccessibility, [String(challengeIdNumbers[0]), String(challengeIdNumbers[1]), String(challengeIdNumbers[2]), String(challengeIdNumbers[3])]))). \(self.helpLabel.text!)"
        codeLabel.accessibilityLabel = challengeIdAccessibilityLabel
        challengeCodeAccessibilityLabel = challengeIdAccessibilityLabel
        if UIAccessibility.isVoiceOverRunning {
            let message: NSAttributedString = NSAttributedString(string: challengeIdAccessibilityLabel, attributes: [.accessibilitySpeechQueueAnnouncement: true])
            UIAccessibility.post(notification: .announcement, argument: message)
        }

        timeoutProgressView.isAccessibilityElement = true

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
        sessionTimer?.invalidate()
        NotificationCenter.default.post(name: .signatureCreatedFinishedNotificationName, object: nil)
        dismiss(animated: false)
    }

    @objc func receiveErrorNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let error = userInfo[kErrorKey] as? NSError
        let signingErrorMessage = (error as? SigningError)?.signingErrorDescription
        let signingError = error?.userInfo[NSLocalizedDescriptionKey] as? SigningError
        let detailedErrorMessage = error?.userInfo[NSLocalizedFailureReasonErrorKey] as? String
        var errorMessage = userInfo[kErrorMessage] as? String ?? SkSigningLib_LocalizedString(signingError?.signingErrorDescription ?? signingErrorMessage ?? "")
        if !detailedErrorMessage.isNilOrEmpty {
            errorMessage = "\(userInfo[kErrorMessage] as? String ?? SkSigningLib_LocalizedString(signingError?.signingErrorDescription ?? signingErrorMessage ?? "")) \n\(detailedErrorMessage ?? "")"
        }
        self.dismiss(animated: false) {
            let topViewController = self.getTopViewController()

            let errorMessageNoLink = errorMessage.removeFirstLinkFromMessage()?.trimWhitespacesAndNewlines()
            let alert = UIAlertController(title: L(.generalSignatureAddingMessage), message: errorMessageNoLink, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            if let linkInUrl = errorMessage.getFirstLinkInMessage() {
                if let alertActionUrl = UIAlertAction().getLinkAlert(message: linkInUrl) {
                    alert.addAction(alertActionUrl)
                }
            }

            topViewController.present(alert, animated: true, completion: nil)
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
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIAccessibility.announcementDidFinishNotification, object: nil)
        sessionTimer?.invalidate()
    }

    @objc func updateSessionProgress(_ timer: Timer) {
        if currentProgress < 1.0 {
            let step: Double = 1.0 / kRequestTimeout
            currentProgress = currentProgress + step
            timeoutProgressView.progress = Float(currentProgress)
            if UIAccessibility.isVoiceOverRunning && timeoutProgressView.isAccessibilityElement {
                Timer.scheduledTimer(withTimeInterval: 7, repeats: false) { timer in
                    UIAccessibility.post(notification: .layoutChanged, argument: self.timeoutProgressView)
                }
            }
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
        content.sound = UNNotificationSound.default
        pendingnotification = UUID().uuidString;
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: pendingnotification, content: content, trigger: nil))
    }
    
    @objc private func handleAccessibility() {
        UIAccessibility.post(notification: .announcement, argument: challengeCodeAccessibilityLabel)
    }
    
    @objc func didFinishAnnouncement(_ notification: Notification) {
        let announcementValue: String? = notification.userInfo?[UIAccessibility.announcementStringValueUserInfoKey] as? String
        let isAnnouncementSuccessful: Bool? = notification.userInfo?[UIAccessibility.announcementWasSuccessfulUserInfoKey] as? Bool
        
        guard let isSuccessful = isAnnouncementSuccessful else {
            return
        }
        
        if !isSuccessful && announcementValue == challengeCodeAccessibilityLabel {
            printLog("Control code announcement was not successful, retrying...")
            UIAccessibility.post(notification: .announcement, argument: announcementValue)
        }
    }
}

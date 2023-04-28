/*
 * MoppApp - SmartIDChallengeViewController.swift
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

import UIKit
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
    var challengeIdNumbers = Array<Character>()
    var isAnnouncementMade = false
    var isProgressBarFocused = false
    
    @IBOutlet weak var cancelButton: ScaledButton!

    @IBAction func cancelSigningButton(_ sender: Any) {
        printLog("Cancelling Mobile-ID signing")
        sessionTimer?.invalidate()
        NotificationCenter.default.post(name: .signatureSigningCancelledNotificationName, object: nil)
        NotificationCenter.default.removeObserver(self)
        cancelButton.isEnabled = false
        cancelButton.backgroundColor = .gray
        cancelButton.tintColor = .white
        RequestCancel.shared.cancelRequest()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        helpLabel.text = L(.smartIdChallengeTitle)
        cancelButton.setTitle(L(.actionAbort))
        cancelButton.accessibilityLabel = L(.actionAbort).lowercased()
        currentProgress = 0
        timeoutProgressView.progress = 0
        RequestCancel.shared.resetCancelRequest()

        NotificationCenter.default.addObserver(self, selector: #selector(receiveSelectAccountNotification), name: .selectSmartIDAccountNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveCreateSignatureNotification), name: .createSignatureNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveCreateSignatureStatus), name: .signatureAddedToContainerNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveErrorNotification), name: .errorNotificationName, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForegroundNotification),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didFinishAnnouncement(_:)),
            name: UIAccessibility.announcementDidFinishNotification,
            object: nil)

        timeoutProgressView.isAccessibilityElement = false

        UIAccessibility.post(notification: .announcement, argument: timeoutProgressView.progress)
    }

    deinit {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [pendingnotification])
        sessionTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    @objc func receiveSelectAccountNotification(_ notification: Notification) {
        helpLabel.text = MoppLib_LocalizedString("smart-id-status-request-select-account")
        
        helpLabel.accessibilityLabel = L(.signTitleSmartId)
        currentProgress = 0.0
        sessionTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateSessionProgress), userInfo: nil, repeats: true)
        
        if UIAccessibility.isVoiceOverRunning {
            DispatchQueue.main.async {
                DispatchQueue(label: "confirmLabel", qos: .userInitiated).sync {
                    let confirmMessage = "\(L(.signingProgress)) \(Int(0))%. \(self.helpLabel.text ?? "")"
                    
                    UIAccessibility.post(notification: .layoutChanged, argument: confirmMessage)
                }
            }
        }
    }

    @objc func receiveCreateSignatureNotification(_ notification: Notification) {
        guard let challengeID = notification.userInfo?[kKeySmartIDChallengeKey] as? String else {
            return
        }

        helpLabel.text = L(.smartIdSignHelpTitle)
        challengeIdNumbers = Array<Character>(challengeID)

        let challengeIdAccessibilityLabel: NSAttributedString = NSAttributedString(string:  "\((L(LocKey.challengeCodeLabelAccessibility, [String(challengeIdNumbers[0]), String(challengeIdNumbers[1]), String(challengeIdNumbers[2]), String(challengeIdNumbers[3])]))). \(self.helpLabel.text!)", attributes: [.accessibilitySpeechQueueAnnouncement: true])
        
        codeLabel.text = L(LocKey.challengeCodeLabel, [challengeID])
        codeLabel.accessibilityLabel = self.getCodeLabelAccessibilityLabel(withProgress: true)
        
        if UIAccessibility.isVoiceOverRunning && !isAnnouncementMade {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                DispatchQueue(label: "challengeLabel", qos: .userInitiated).sync {
                    UIAccessibility.post(notification: .announcement, argument: challengeIdAccessibilityLabel)
                }
            }
        }
        
        codeLabel.isHidden = false

        currentProgress = 0.0

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
        DispatchQueue.main.async {
            self.dismiss(animated: false) {
                let topViewController = self.getTopViewController()
                AlertUtil.errorMessageDialog(notification, topViewController: topViewController)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        UIView.animate(withDuration: 0.35) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
        
        cancelButton.isEnabled = true
    }

    @objc func updateSessionProgress(_ timer: Timer) {
        if currentProgress < 1.0 {
            let step: Double = 1.0 / kRequestTimeout
            currentProgress = currentProgress + step
            timeoutProgressView.progress = Float(currentProgress)
            
            if UIAccessibility.isVoiceOverRunning && timeoutProgressView.isAccessibilityElement && isAnnouncementMade && !isProgressBarFocused {
                UIAccessibility.post(notification: .layoutChanged, argument: self.timeoutProgressView)
                isProgressBarFocused = true
            } else if UIAccessibility.isVoiceOverRunning && isAnnouncementMade && isProgressBarFocused {
                codeLabel.accessibilityLabel = getCodeLabelAccessibilityLabel(withProgress: false)
                UIAccessibility.post(notification: .announcement, argument: currentProgress)
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
        DispatchQueue.main.async {
            self.codeLabel.accessibilityLabel = nil
            self.announceCodeLabelAccessibilityLabel()
        }
    }
    
    @objc func didFinishAnnouncement(_ notification: Notification) {
        let announcementValue: String? = notification.userInfo?[UIAccessibility.announcementStringValueUserInfoKey] as? String
        let isAnnouncementSuccessful: Bool? = notification.userInfo?[UIAccessibility.announcementWasSuccessfulUserInfoKey] as? Bool
        
        guard let isSuccessful = isAnnouncementSuccessful else {
            return
        }
        
        if let value = announcementValue,  value.contains(getCodeLabelAccessibilityLabel(withProgress: false)) && !isSuccessful {
            printLog("Control code announcement was not successful, retrying...")
            UIAccessibility.post(notification: .announcement, argument: announcementValue)
        } else if let value = announcementValue, value.contains(MoppLib_LocalizedString("smart-id-status-request-select-account")) && isSuccessful {
            codeLabel.accessibilityLabel = "\(L(.signingProgress)) \(Int(currentProgress * 100))%. \(MoppLib_LocalizedString("smart-id-status-request-select-account"))"
        } else if isSuccessful {
            self.isAnnouncementMade = true
            self.codeLabel.isAccessibilityElement = true
            self.timeoutProgressView.isAccessibilityElement = true
            self.helpLabel.isAccessibilityElement = true
            self.cancelButton.isAccessibilityElement = true
            self.cancelButton.titleLabel?.isAccessibilityElement = true
            codeLabel.accessibilityLabel = getCodeLabelAccessibilityLabel(withProgress: false)
        }
    }
    
    func getCodeLabelAccessibilityLabel(withProgress: Bool) -> String {
        let signingProgess = "\(L(.signingProgress)) \(Int(currentProgress * 100))%. "
        let codeLabelText = "\((L(LocKey.challengeCodeLabelAccessibility, [String(challengeIdNumbers[0]), String(challengeIdNumbers[1]), String(challengeIdNumbers[2]), String(challengeIdNumbers[3])]))). \(self.helpLabel.text!)"
        let codeLabelMessage = withProgress ? signingProgess + codeLabelText : codeLabelText
        return codeLabelMessage
    }
    
    func announceCodeLabelAccessibilityLabel() {
        let codeLabelMessage =  getCodeLabelAccessibilityLabel(withProgress: true)
        UIAccessibility.post(notification: .announcement, argument: codeLabelMessage)
    }
    
    @objc func appWillEnterForegroundNotification() {
        self.codeLabel.accessibilityLabel = nil
        self.codeLabel.isAccessibilityElement = false
        self.timeoutProgressView.isAccessibilityElement = false
        self.helpLabel.isAccessibilityElement = false
        self.cancelButton.isAccessibilityElement = false
        self.cancelButton.titleLabel?.isAccessibilityElement = false
        DispatchQueue.main.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                DispatchQueue(label: "codeLabel", qos: .userInitiated).sync {
                    let codeLabelMessage = self.getCodeLabelAccessibilityLabel(withProgress: true)
                    UIAccessibility.post(notification: .announcement, argument: codeLabelMessage)
                }
            }
        }
    }
}

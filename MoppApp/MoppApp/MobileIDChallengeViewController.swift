//
//  MobileIDChallengeViewController.swift
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
import SkSigningLib

private var kRequestTimeout: Double = 120.0

class MobileIDChallengeViewController : UIViewController {

    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var timeoutProgressView: UIProgressView!
    @IBOutlet weak var helpLabel: UILabel!

    var challengeID = String()

    var currentProgress: Double = 0.0
    var sessionTimer: Timer?

    var isAnnouncementMade = false
    var isProgressBarFocused = false
    var challengeIdAccessibilityLabel = ""
    var challengeIdNumbers = Array<Character>()
    
    @IBOutlet weak var cancelButton: ScaledLabel!
    
    
    @objc func cancelSigningButton(_ sender: UITapGestureRecognizer) {
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

        helpLabel.text = L(.mobileIdSignHelpTitle)
        cancelButton.text = L(.actionAbort)
        cancelButton.accessibilityLabel = L(.actionAbort).lowercased()
        
        if let cancelTitleLabel = cancelButton {
            let maxSize: CGFloat = 17
            let currentFontSize = cancelTitleLabel.font.pointSize
            cancelTitleLabel.font = cancelTitleLabel.font.withSize(min(maxSize, currentFontSize))
        }
        
        if !(self.cancelButton.gestureRecognizers?.contains(where: { $0 is UITapGestureRecognizer }) ?? false) {
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.cancelSigningButton(_:)))
            self.cancelButton.addGestureRecognizer(tapGesture)
            self.cancelButton.isUserInteractionEnabled = true
        }
        
        codeLabel.isHidden = true
        currentProgress = 0
        timeoutProgressView.progress = 0
        timeoutProgressView.accessibilityUserInputLabels = [""]
        RequestCancel.shared.resetCancelRequest()

        NotificationCenter.default.addObserver(self, selector: #selector(receiveCreateSignatureStatus), name: .signatureAddedToContainerNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveErrorNotification), name: .errorNotificationName, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveMobileCreateSignatureNotification),
            name: .createSignatureNotificationName,
            object: nil)
        
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
    }

    @objc func didFinishAnnouncement(_ notification: Notification) {
        let announcementValue: String? = notification.userInfo?[UIAccessibility.announcementStringValueUserInfoKey] as? String
        let isAnnouncementSuccessful: Bool? = notification.userInfo?[UIAccessibility.announcementWasSuccessfulUserInfoKey] as? Bool

        guard let isSuccessful = isAnnouncementSuccessful else {
            return
        }

        if !isSuccessful {
            printLog("Control code announcement was not successful, retrying...")
            UIAccessibility.post(notification: .announcement, argument: announcementValue)
        } else {
            self.isAnnouncementMade = true
            
            if !challengeIdNumbers.isEmpty {
                codeLabel.accessibilityLabel = "\(L(.signingProgress)) \(Int(currentProgress * 100))%. \((L(LocKey.challengeCodeLabelAccessibility, [String(challengeIdNumbers[0]), String(challengeIdNumbers[1]), String(challengeIdNumbers[2]), String(challengeIdNumbers[3])]))). \(self.helpLabel.text ?? "")"
            } else {
                codeLabel.accessibilityLabel = self.helpLabel.text ?? ""
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func receiveCreateSignatureStatus(_ notification: Notification) {
        sessionTimer?.invalidate()
        NotificationCenter.default.post(name: .signatureCreatedFinishedNotificationName, object: nil)
        NotificationCenter.default.removeObserver(self)
        dismiss(animated: false)
    }

    @objc func receiveMobileCreateSignatureNotification(_ notification: Notification) {

        guard let challengeID = notification.userInfo?[kCreateSignatureResponseKey] as? String else {
            return
        }

        challengeIdNumbers = Array<Character>(challengeID)

        let challengeIdAccessibilityLabel: NSAttributedString = NSAttributedString(string: "\(L(.signingProgress)) \(Int(0))%. \((L(LocKey.challengeCodeLabelAccessibility, [String(challengeIdNumbers[0]), String(challengeIdNumbers[1]), String(challengeIdNumbers[2]), String(challengeIdNumbers[3])]))). \(self.helpLabel.text!)", attributes: [.accessibilitySpeechQueueAnnouncement: true])

        codeLabel.text = L(LocKey.challengeCodeLabel, [challengeID])
        codeLabel.accessibilityLabel = L(.signTitleMobileId)
        
        if UIAccessibility.isVoiceOverRunning && !isAnnouncementMade {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                DispatchQueue(label: "challengeLabel", qos: .userInitiated).sync {
                    UIAccessibility.post(notification: .announcement, argument: challengeIdAccessibilityLabel)
                }
            }
        }
        codeLabel.isHidden = false

        currentProgress = 0.0

        sessionTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateSessionProgress), userInfo: nil, repeats: true)
    }

    @objc func receiveErrorNotification(_ notification: Notification) {
        DispatchQueue.main.async {
            self.sessionTimer?.invalidate()
            self.dismiss(animated: false) {
                let topViewController = self.getTopViewController()
                AlertUtil.errorMessageDialog(notification, topViewController: topViewController)
            }
        }
    }

    func showErrorDialog(errorMessage: String) -> Void {
        DispatchQueue.main.async {
            self.dismiss(animated: false) {
                let topViewController = self.getTopViewController()

                let errorMessageNoLink: String? = errorMessage.removeFirstLinkFromMessage()?.trimWhitespacesAndNewlines()

                let alert = UIAlertController(title: L(.generalSignatureAddingMessage), message: errorMessageNoLink, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                if let linkInUrl: String = errorMessage.getFirstLinkInMessage() {
                    if let alertActionUrl: UIAlertAction = UIAlertAction().getLinkAlert(message: linkInUrl), !alertActionUrl.title.isNilOrEmpty {
                        alert.addAction(alertActionUrl)
                    }
                }

                if !(topViewController is UIAlertController) {
                    topViewController.present(alert, animated: true, completion: nil)
                }
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionTimer?.invalidate()
    }

    @objc func updateSessionProgress(_ timer: Timer) {
        if currentProgress < 1.0 {
            let step: Double = 1.0 / kRequestTimeout
            currentProgress = currentProgress + step
            timeoutProgressView.progress = Float(currentProgress)
            if UIAccessibility.isVoiceOverRunning && isAnnouncementMade && !isProgressBarFocused {
                UIAccessibility.post(notification: .layoutChanged, argument: self.timeoutProgressView)
                isProgressBarFocused = true
            } else if UIAccessibility.isVoiceOverRunning && isAnnouncementMade && isProgressBarFocused {
                setCodeLabelAccessibilityLabel()
                UIAccessibility.post(notification: .announcement, argument: currentProgress)
            }
        } else {
            timer.invalidate()
            dismiss(animated: false, completion: nil)
        }
    }
    
    func setCodeLabelAccessibilityLabel() {
        if codeLabel != nil && challengeIdNumbers != nil && !challengeIdNumbers.isEmpty {
            codeLabel.accessibilityLabel = "\(L(.signingProgress)) \(Int(currentProgress * 100))%. \((L(LocKey.challengeCodeLabelAccessibility, [String(challengeIdNumbers[0]), String(challengeIdNumbers[1]), String(challengeIdNumbers[2]), String(challengeIdNumbers[3])]))). \(self.helpLabel.text!)"
        }
    }
    
    @objc func appWillEnterForegroundNotification() {
        setCodeLabelAccessibilityLabel()
    }

}

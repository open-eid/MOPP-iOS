//
//  MobileIDChallengeViewController.swift
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

private var kRequestTimeout: Double = 60.0

class MobileIDChallengeViewController : UIViewController {
    
    @IBOutlet weak var mobileIDChallengeCodeLabel: UILabel!
    @IBOutlet weak var mobileIDSessionCounter: UIProgressView!
    
    var challengeID = ""
    var sessCode = ""

    var currentProgress: Double = 0.0
    var sessionTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        mobileIDChallengeCodeLabel.text = L(LocKey.ChallengeCodeLabel, challengeID)
        currentProgress = 0.0
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveCreateSignatureStatus), name: .signatureAddedToContainerNotificationName, object: nil)
        sessionTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateSessionProgress), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func receiveCreateSignatureStatus(_ notification: Notification) {
        sessionTimer?.invalidate()
        dismiss(animated: true)
    }

    func viewWillDisAppear(_ animated: Bool) {
        sessionTimer?.invalidate()
    }

    @objc func updateSessionProgress(_ timer: Timer) {
        if currentProgress < 1.0 {
            let step: Double = 1.0 / kRequestTimeout
            currentProgress = currentProgress + step
            mobileIDSessionCounter.progress = Float(currentProgress)
        }
        else {
            timer.invalidate()
            MoppLibService.sharedInstance().cancelMobileSignatureStatusPolling()
            NotificationCenter.default.post(name: .errorNotificationName, object: nil, userInfo: [kErrorMessage: L(.MobileIdTimeoutMessage)])
        }
    }

}

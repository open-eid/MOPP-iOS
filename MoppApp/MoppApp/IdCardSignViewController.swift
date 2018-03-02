//
//  IdCardSignViewController.swift
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
protocol IdCardSignViewControllerDelegate : class {
    func idCardViewControllerDidDismiss(cancelled: Bool)
}

class IdCardSignViewController : MoppViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pin2TextField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var signButton: UIButton!
    @IBOutlet weak var pin2TextFieldTitleLabel: UILabel!
    @IBOutlet weak var loadingSpinner: SpinnerView!
    @IBOutlet weak var cancelButtonTrailingToSuperViewCSTR: NSLayoutConstraint!
    @IBOutlet weak var cancelButtonTrailingToSignButtonCSTR: NSLayoutConstraint!
    @IBOutlet weak var titleLabelBottomToCancelButtonCSTR: NSLayoutConstraint!
    @IBOutlet weak var titleLabelBottomToPin2TextFieldCSTR: NSLayoutConstraint!
    
    weak var delegate: IdCardSignViewControllerDelegate!
    
    enum State {
        case waitingConnection
        case cardConnected
    }
    
    var state: State = .waitingConnection {
        didSet {
            updateStateUI(newState: state)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        cancelButton.setTitle(L(.actionCancel).uppercased())
        signButton.setTitle(L(.actionSign).uppercased())
    
        pin2TextField.layer.borderColor = UIColor.moppContentLine.cgColor
        pin2TextField.layer.borderWidth = 1.0
        pin2TextField.moppPresentDismissButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        state = .waitingConnection
        loadingSpinner.show(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
            self.changeState()
        })
    }
    
    @objc func changeState() {
        state = .cardConnected
    }
    
    func updateStateUI(newState: State) {
        switch newState {
        case .cardConnected:
            signButton.isHidden = false
            pin2TextField.isHidden = false
            pin2TextFieldTitleLabel.isHidden = false
            loadingSpinner.isHidden = true
            cancelButtonTrailingToSuperViewCSTR.priority = UILayoutPriority.defaultLow
            cancelButtonTrailingToSignButtonCSTR.priority = UILayoutPriority.defaultHigh
            titleLabel.text = L(.cardReaderStateReady)
        case .waitingConnection:
            signButton.isHidden = true
            pin2TextField.isHidden = true
            pin2TextFieldTitleLabel.isHidden = true
            loadingSpinner.isHidden = false
            cancelButtonTrailingToSuperViewCSTR.priority = UILayoutPriority.defaultHigh
            cancelButtonTrailingToSignButtonCSTR.priority = UILayoutPriority.defaultLow
            titleLabel.text = L(.cardReaderStateNotReady)
        }
        
        view.layoutIfNeeded()
    }
    
    override func willEnterForeground() {
        super.willEnterForeground()
        loadingSpinner.show(true)
    }
    
    @IBAction func cancelAction() {
        dismiss(animated: false) {
            [weak self] in
            self?.delegate?.idCardViewControllerDidDismiss(cancelled: true)
        }
    }
    
    @IBAction func signAction() {
        dismiss(animated: false) {
            [weak self] in
            self?.delegate?.idCardViewControllerDidDismiss(cancelled: false)
        }
    }
}

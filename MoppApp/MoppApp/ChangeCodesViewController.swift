//
//  ChangeCodesViewController.swift
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
class ChangeCodesViewController: MoppViewController {
    @IBOutlet weak var ui: ChangeCodesViewControllerUI!
    var model = MyeIDChangeCodesModel()
    
    private var loadingViewController: ChangeCodesLoadingViewController! = {
        let loadingViewController = UIStoryboard.myEID.instantiateViewController(of: ChangeCodesLoadingViewController.self)
            loadingViewController.modalPresentationStyle = .overFullScreen
        return loadingViewController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LandingViewController.shared.presentButtons([])
        ui.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ui.setupWithModel(model, self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
}

extension ChangeCodesViewController: ChangeCodesViewControllerUIDelegate {
    func didTapDiscardButton(_ ui: ChangeCodesViewControllerUI) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func didTapConfirmButton(_ ui: ChangeCodesViewControllerUI) {
        let failureClosure = { [weak self] (error: Error?) in
            guard let strongSelf = self else { return }
            ui.clearCodeTextFields()
            var errorMessage = L(.genericErrorMessage)
            if let nsError = error as NSError? {
                let actionType = strongSelf.model.actionType
                if nsError.code == MoppLibErrorCode.moppLibErrorWrongPin.rawValue {
                    let retryCount = (nsError.userInfo[kMoppLibUserInfoRetryCount] as? NSNumber)?.intValue ?? 0
                    MyeIDInfoManager.shared.retryCounts.retryCount(for: actionType, with: retryCount)
                    if retryCount == 0 {
                        errorMessage = L(.myEidCodeBlockedMessage, [actionType.associatedCodeName(), actionType.associatedCodeName()])
                    }
                    else if retryCount == 1 {
                        errorMessage = L(.myEidWrongCodeMessageSingular, [actionType.associatedCodeName()])
                    }
                    else {
                        errorMessage = L(.myEidWrongCodeMessage, [3-retryCount, actionType.associatedCodeName(), retryCount])
                    }
                }
                else if let localizedDescription = nsError.userInfo["NSLocalizedDescription"] as? String {
                    self?.loadingViewController.dismiss(animated: false, completion: {
                        self?.errorAlert(message: localizedDescription)
                    })
                }
            }
            self?.loadingViewController.dismiss(animated: false, completion: {
                self?.errorAlert(message: errorMessage)
            })
        }
        let commonSuccessClosure = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loadingViewController.dismiss(animated: false) {
                ui.clearCodeTextFields()
                var statusText = String()
                switch strongSelf.model.actionType {
                case .changePin1:
                    statusText = L(.myEidCodeChangedSuccessMessage, ["PIN1"])
                case .changePin2:
                    statusText = L(.myEidCodeChangedSuccessMessage, ["PIN2"])
                case .unblockPin1:
                    statusText = L(.myEidCodeUnblockedSuccessMessage, ["PIN1"])
                    MyeIDInfoManager.shared.retryCounts.pin1 = 3
                case .unblockPin2:
                    statusText = L(.myEidCodeUnblockedSuccessMessage, ["PIN2"])
                    MyeIDInfoManager.shared.retryCounts.pin2 = 3
                case .changePuk:
                    statusText = L(.myEidCodeChangedSuccessMessage, ["PUK"])
                }
                ui.showStatusView(with: statusText)
            }
        }
        let oldCode = ui.firstCodeTextField.text ?? String()
        let newCode = ui.secondCodeTextField.text ?? String()
        let pukCode = oldCode
        
        // code length validation
        
        // show spinner
        present(loadingViewController, animated: false) { [weak self] in
            guard let strongSelf = self else { return }
            switch strongSelf.model.actionType {
            case .changePin1:
                MoppLibPinActions.changePin1(to: newCode, withOldPin1: oldCode, viewController: self, success: {
                    commonSuccessClosure()
                }, failure: failureClosure)
                
            case .changePin2:
                MoppLibPinActions.changePin2(to: newCode, withOldPin2: oldCode, viewController: self, success: {
                    commonSuccessClosure()
                }, failure: failureClosure)
                
            case .unblockPin1:
                MoppLibPinActions.changePin1(to: newCode, withPuk: pukCode, viewController: self, success: {
                    commonSuccessClosure()
                }, failure: failureClosure)
                
            case .unblockPin2:
                MoppLibPinActions.changePin2(to: newCode, withPuk: pukCode, viewController: self, success: {
                    commonSuccessClosure()
                }, failure: failureClosure)
                
            case .changePuk:
                MoppLibPinActions.changePuk(to: newCode, withOldPuk: oldCode, viewController: self, success: {
                    commonSuccessClosure()
                }, failure: failureClosure)
            }
        }
    }
}

@objc
protocol ChangeCodesViewControllerUIDelegate: class {
    func didTapDiscardButton(_ ui: ChangeCodesViewControllerUI)
    func didTapConfirmButton(_ ui: ChangeCodesViewControllerUI)
}

class ChangeCodesViewControllerUI: NSObject {
    @IBOutlet weak var delegate: ChangeCodesViewControllerUIDelegate!
    private weak var viewController: ChangeCodesViewController!
    private var isKeyboardVisible = false
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewContentView: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var firstCodeTextField: UITextField!
    @IBOutlet weak var secondCodeTextField: UITextField!
    @IBOutlet weak var thirdCodeTextField: UITextField!
    @IBOutlet weak var firstCodeTextFieldLabel: UILabel!
    @IBOutlet weak var secondCodeTextFieldLabel: UILabel!
    @IBOutlet weak var thirdCodeTextFieldLabel: UILabel!
    @IBOutlet weak var firstInlineErrorLabel: UILabel!
    @IBOutlet weak var secondInlineErrorLabel: UILabel!
    @IBOutlet weak var thirdInlineErrorLabel: UILabel!
    @IBOutlet weak var statusViewVisibleCSTR: NSLayoutConstraint!
    @IBOutlet weak var statusViewHiddenCSTR: NSLayoutConstraint!
    @IBOutlet weak var statusLabel: UILabel!
    
    var currentPin1TextField: UITextField { get { return firstCodeTextField }}
    var newPin1TextField: UITextField { get { return secondCodeTextField }}
    var newPin1ControlTextField: UITextField { get { return secondCodeTextField }}
    
    var currentPukTextField: UITextField { get { return firstCodeTextField }}
    var newPukTextField: UITextField { get { return secondCodeTextField }}
    var newPukControlTextField: UITextField { get { return secondCodeTextField }}
    
    var currentPin12extField: UITextField { get { return firstCodeTextField }}
    var newPin2TextField: UITextField { get { return secondCodeTextField }}
    var newPin2ControlTextField: UITextField { get { return secondCodeTextField }}
    
    @IBAction func discardButtonTapped() {
        delegate.didTapDiscardButton(self)
    }
    
    @IBAction func confirmButtonTapped() {
        delegate.didTapConfirmButton(self)
    }
    
    func setupWithModel(_ model: MyeIDChangeCodesModel, _ controller: ChangeCodesViewController) {
        viewController = controller
        controller.setupNavigationItemForPushedViewController(title: model.titleText)
        firstCodeTextFieldLabel.text = model.firstTextFieldLabelText
        secondCodeTextFieldLabel.text = model.secondTextFieldLabelText
        thirdCodeTextFieldLabel.text = model.thirdTextFieldLabelText
        discardButton.setTitle(model.discardButtonTitleText)
        confirmButton.setTitle(model.confirmButtonTitleText)
        
        firstCodeTextField.delegate = self
        secondCodeTextField.delegate = self
        thirdCodeTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        let font = UIFont(name: MoppFontName.regular.rawValue, size: 16)!
        let color = UIColor.moppText
        let attributes = [NSAttributedStringKey.font : font, NSAttributedStringKey.foregroundColor : color]
        
        let fullAttributedString = NSMutableAttributedString()
        
        let textAttachment = NSTextAttachment()
            textAttachment.image = UIImage(named: "bullet")!.withRenderingMode(.alwaysTemplate)
        
        for index in 0..<model.infoBullets.count {
            let infoBullet = model.infoBullets[index]
            let attributedString: NSMutableAttributedString = NSMutableAttributedString(
                    string: String(), attributes: attributes)
                attributedString.append(NSAttributedString(string: String.zeroWidthSpace, attributes: attributes))
                attributedString.append(NSAttributedString(attachment: textAttachment))
                attributedString.append(NSAttributedString(string: "\t\(infoBullet)", attributes: attributes))
            if index < (model.infoBullets.count - 1) {
                attributedString.append(NSAttributedString(string: "\n", attributes: attributes))
            }
            
            let paragraphStyle = createParagraphAttribute()
            attributedString.addAttributes(
                attributes.merging([NSAttributedStringKey.paragraphStyle: paragraphStyle],
                    uniquingKeysWith: {current,_  in return current }),
                range: NSMakeRange(0, attributedString.length))
            
            fullAttributedString.append(attributedString)
        }
        
        textView.attributedText = fullAttributedString
        
        statusViewHiddenCSTR.priority = UILayoutPriority.defaultHigh
        statusViewVisibleCSTR.priority = UILayoutPriority.defaultLow
    }
    
    func createParagraphAttribute() -> NSParagraphStyle
    {
        var paragraphStyle: NSMutableParagraphStyle
        paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 30, options: [:])]
        paragraphStyle.defaultTabInterval = 30
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 30
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.firstLineHeadIndent = 0
        
        return paragraphStyle
    }
    
    @objc func adjustForKeyboard(notification: NSNotification) {
        
        if notification.name == NSNotification.Name.UIKeyboardWillHide {
            scrollView.contentInset = UIEdgeInsets.zero
            isKeyboardVisible = false
        
        } else if notification.name == NSNotification.Name.UIKeyboardWillShow {
            if isKeyboardVisible { return }
            
            let userInfo = notification.userInfo!
            
            let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let keyboardViewEndFrame = viewController.view.convert(keyboardScreenEndFrame, from: viewController.view.window)
            
            let scrollViewRectInWindow = scrollView.convert(scrollView.frame, from: viewController.view.window)
            let bottomMargin = (viewController.view.window?.frame.height ?? 0) - (scrollViewRectInWindow.height - scrollViewRectInWindow.origin.y)
            
            var bottomContentInset = keyboardViewEndFrame.height - bottomMargin + 8
            
            let scrollViewContentDelta = scrollView.contentSize.height - scrollView.frame.height
            if scrollViewContentDelta > 0 {
                bottomContentInset += scrollViewContentDelta
            }
        
            scrollView.contentInset = UIEdgeInsetsMake(0, 0, bottomContentInset, 0)
            isKeyboardVisible = true
        }
    }
    
    func showStatusView(with title: String) {
        statusLabel.text = title
        UIView.animate(withDuration: 0.35, delay: 0.0, options: UIViewAnimationOptions.curveLinear, animations: { [weak self] in
            self?.statusViewHiddenCSTR.priority = UILayoutPriority.defaultLow
            self?.statusViewVisibleCSTR.priority = UILayoutPriority.defaultHigh
            self?.viewController.view.layoutIfNeeded()
        }) { (finished) in
            UIView.animate(withDuration: 0.35, delay: 3.0, options: UIViewAnimationOptions.curveLinear, animations: { [weak self] in
                self?.statusViewHiddenCSTR.priority = UILayoutPriority.defaultHigh
                self?.statusViewVisibleCSTR.priority = UILayoutPriority.defaultLow
                self?.viewController.view.layoutIfNeeded()
            }) { (finished) in }
        }
    }
    
    func clearCodeTextFields() {
        firstCodeTextField.text = nil
        secondCodeTextField.text = nil
        thirdCodeTextField.text = nil
    }
}

extension ChangeCodesViewControllerUI: UITextFieldDelegate {    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

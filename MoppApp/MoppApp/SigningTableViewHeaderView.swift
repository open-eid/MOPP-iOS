//
//  SigningTableViewHeaderView.swift
//  MoppApp
//
/*
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
import Foundation

protocol SigningTableViewHeaderViewDelegate: AnyObject {
    func signingTableViewHeaderViewSearchKeyChanged(_ searchKeyValue: String)
    func signingTableViewHeaderViewDidEndSearch()
}

class SigningTableViewHeaderView: UIView {
    static let height: CGFloat = 44
    weak var delegate: SigningTableViewHeaderViewDelegate?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchTextField: SearchTextField!
    
    @IBAction func searchTapped() {
        searchTextField.isAccessibilityElement = true
        showSearch(true, animated: true)
    }
    
    var requestForClosingKeyboard: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        searchTextField._delegate = self
        guard let titleUILabel = titleLabel, let searchUIButton = searchButton, let searchUITextField = searchTextField else {
            printLog("Unable to get titleLabel, searchButton or searchTextField")
            return
        }
        searchUITextField.isAccessibilityElement = false
        self.accessibilityElements = [titleUILabel, searchUIButton]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let topColor = UIColor.white.withAlphaComponent(1.0)
        let botColor = UIColor.white.withAlphaComponent(0.8)
        createGradientLayer(topColor: topColor, bottomColor: botColor)
    }
    
    func populate(title: String, _ requestCloseSearch: inout () -> Void) {
        titleLabel.text = title
        requestCloseSearch = { [weak self] in
            self?.showSearch(false, animated: false)
        }
    }
    
    func showSearch(_ show: Bool, animated: Bool) {
        
        self.titleLabel.alpha = show ? 1.0 : 0.0
        self.searchButton.alpha = show ? 1.0 : 0.0
        self.searchTextField.alpha = show ? 0.0 : 1.0
        self.titleLabel.isHidden = false
        self.searchButton.isHidden = false
        self.searchTextField.isHidden = false
    
        let changeTo = {
            if !UIAccessibility.isVoiceOverRunning {
                self.titleLabel.alpha = show ? 0.0 : 1.0
                self.searchButton.alpha = show ? 0.0 : 1.0
                self.searchTextField.alpha = show ? 1.0 : 0.0
            } else {
                self.titleLabel.alpha = 0.0
                self.searchButton.alpha = 0.0
                self.searchTextField.alpha = 1.0
            }
        }
        
        let changeFinished = {
            if !UIAccessibility.isVoiceOverRunning {
                self.titleLabel.isHidden = show
                self.searchButton.isHidden = show
                self.searchTextField.isHidden = !show
            }
            if show {
                self.searchTextField.becomeFirstResponder()
            } else {
                if !UIAccessibility.isVoiceOverRunning {
                    self.searchTextField.resignFirstResponder()
                    self.searchTextField.text = nil
                    self.delegate?.signingTableViewHeaderViewDidEndSearch()
                } else {
                    self.titleLabel.isHidden = false
                    self.searchButton.isHidden = false
                    self.searchTextField.isHidden = false
                }
            }
        }
    
        if animated {
            UIView.animate(withDuration: 0.35, animations: {
                changeTo()
            }) { _ in
                changeFinished()
            }
        } else {
            changeTo()
            changeFinished()
        }

    }
}

extension SigningTableViewHeaderView: SearchTextFieldDelegate {
    func searchTextFieldDidEndEditing() {
        showSearch(false, animated: true)
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: self.searchTextField)
    }
    
    func searchTextFieldValueChanged(_ newValue: String) {
        delegate?.signingTableViewHeaderViewSearchKeyChanged(newValue)
    }
}

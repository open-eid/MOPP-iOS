//
//  SigningTableViewHeaderView.swift
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

protocol SigningTableViewHeaderViewDelegate: AnyObject {
    func signingTableViewHeaderViewSearchKeyChanged(_ searchKeyValue: String)
    func signingTableViewHeaderViewDidEndSearch()
}

class SigningTableViewHeaderView: UIView {
    weak var delegate: SigningTableViewHeaderViewDelegate?
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchTextField: SearchTextField!
    
    @IBAction func searchTapped() {
        searchTextField.isAccessibilityElement = true
        showSearch(true, animated: true)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        searchTextField._delegate = self
        guard let searchUIButton = searchButton, let searchUITextField = searchTextField else {
            printLog("Unable to get searchButton or searchTextField")
            return
        }
        searchUITextField.isAccessibilityElement = false
        if UIAccessibility.isVoiceOverRunning {
            self.accessibilityElements = [searchUIButton]
        }
    }
    
    func populate(title: String, _ requestCloseSearch: inout () -> Void) {
        self.searchButton.accessibilityUserInputLabels = [L(.voiceControlSearch)]
    }
    
    func showSearch(_ show: Bool, animated: Bool) {
        self.searchButton.accessibilityLabel = L(.searchContainerFile)
        self.searchButton.titleLabel?.font = UIFont.moppLargerMedium
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

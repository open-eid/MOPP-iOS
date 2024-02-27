//
//  SearchTextField.swift
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
import Foundation

protocol SearchTextFieldDelegate: AnyObject {
    func searchTextFieldDidEndEditing()
    func searchTextFieldValueChanged(_ newValue: String)
}

class SearchTextField: ScaledTextField {

    weak var _delegate: SearchTextFieldDelegate?

    let padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    let rightViewPadding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)

    override func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
        textColor = UIColor.moppText
        attributedPlaceholder = NSAttributedString(string: L(.searchContainerFile), attributes: [NSAttributedString.Key.foregroundColor: UIColor.moppPlaceholderDarker])
        
        addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
    }

    deinit {
        removeTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
    }

    override var text: String? {
        didSet {
            showClearIndicator(text == nil)
            _delegate?.searchTextFieldValueChanged(text ?? String())
        }
    }

    @objc func clearTapped() {
        text = nil
        _delegate?.searchTextFieldValueChanged(String())
    }

    @objc func editingChanged(sender: UITextField) {
        let text = sender.text ?? String()
        showClearIndicator(!text.isEmpty)
        _delegate?.searchTextFieldValueChanged(text)
    }

    func showClearIndicator(_ show: Bool) {
        if show {
            if rightView == nil {
                rightViewMode = .always
                let clearButton = UIButton(type: .custom)
                clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
                clearButton.isAccessibilityElement = !UIAccessibility.isVoiceOverRunning
                clearButton.imageView?.isAccessibilityElement = true
                clearButton.accessibilityUserInputLabels = [L(.voiceControlClearText)]
                clearButton.imageView?.accessibilityLabel = "Clear"
                clearButton.imageView?.accessibilityUserInputLabels = [L(.voiceControlClearText)]
                rightView = clearButton
            }
        } else {
            rightView = nil
        }
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func shouldChangeText(in range: UITextRange, replacementText text: String) -> Bool {

        return true
    }
}

extension SearchTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {

    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        _delegate?.searchTextFieldDidEndEditing()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        UIAccessibility.isVoiceOverRunning ? showClearIndicator(true) : showClearIndicator(false)
        textField.resignFirstResponder()
        return true
    }
}

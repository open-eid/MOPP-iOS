//
//  SearchTextField.swift
//  MoppApp
//
/*
 * Copyright 2021 Riigi Infosüsteemi Amet
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

protocol SearchTextFieldDelegate: class {
    func searchTextFieldDidEndEditing()
    func searchTextFieldValueChanged(_ newValue: String)
}


class SearchTextField: UITextField {

    weak var _delegate: SearchTextFieldDelegate?

    let padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    let rightViewPadding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)

    override func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
        font = UIFont.moppTextField
        textColor = UIColor.moppText
        attributedPlaceholder = NSAttributedString(string: L(.searchContainerFile), attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)])
        
        addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
    }

    deinit {
        removeTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
    }

    override var text: String? {
        didSet {
            showClearIndicator(text == nil)
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
                rightViewMode = UIAccessibilityIsVoiceOverRunning() ? .always : .whileEditing
                let clearButton = UIButton(frame: CGRect(x: 0, y: 0, width: 56, height: 44))
                    clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
                    clearButton.setImage(UIImage(named: "DismissPopup"), for: .normal)
                    clearButton.backgroundColor = UIColor.clear
                    clearButton.tintColor = textColor
                rightView = clearButton
            }
        } else {
            rightView = nil
        }
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    //override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
    //    return UIEdgeInsetsInsetRect(CGRect(x: 0, y: 0, width: 25, height: 25), rightViewPadding)
    //}
    
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
        UIAccessibilityIsVoiceOverRunning() ? showClearIndicator(true) : showClearIndicator(false)
        textField.resignFirstResponder()
        return true
    }
}

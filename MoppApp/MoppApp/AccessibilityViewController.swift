//
//  AccessibilityViewController.swift
//  MoppApp
//
/*
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

import Foundation

class AccessibilityViewController : MoppViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var textView: UITextView!
    
    @IBAction func dismissAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = L(.accessibilityIntroductionTitle)
        
        textView.attributedText = accessibilityIntroductionText()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func textStyle(text: String, textType: AccessibilityViewTextType) -> NSAttributedString {
        var attributes: [NSAttributedString.Key : AnyObject]
        switch textType {
        case .header:
            if let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title1).withSymbolicTraits(.traitBold) {
                attributes = [NSAttributedString.Key.font : UIFont(descriptor: fontDescriptor, size: fontDescriptor.pointSize), NSAttributedString.Key.foregroundColor : UIColor.moppTitle]
            } else {
                attributes = [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .headline), NSAttributedString.Key.foregroundColor : UIColor.moppTitle]
            }
            return NSMutableAttributedString(string: "\n\n\(text)\n", attributes:attributes)
        case .paragraph:
            attributes = [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .body), NSAttributedString.Key.foregroundColor : UIColor.moppTitle]
            break
        case .boldText:
            if let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSymbolicTraits(.traitBold) {
                attributes = [NSAttributedString.Key.font : UIFont(descriptor: fontDescriptor, size: fontDescriptor.pointSize), NSAttributedString.Key.foregroundColor : UIColor.moppTitle]
            } else {
                attributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.moppTitle]
            }
            break
        }
        
        return NSMutableAttributedString(string: "\n\(text)\n", attributes:attributes)
    }
    
    private func accessibilityIntroductionText() -> NSAttributedString {
        
        let introText: NSMutableAttributedString = NSMutableAttributedString()
        introText.append(textStyle(text: L(.accessibilityIntroduction), textType: .paragraph))
        introText.append(textStyle(text: L(.accessibilityIntroduction2), textType: .paragraph))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenReaderHeader), textType: .header))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenReaderIntroduction), textType: .paragraph))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenReaderIntroduction2), textType: .paragraph))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenReaderIntroductionApps), textType: .boldText))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenReaderIntroductioniOS), textType: .paragraph))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenReaderIntroductionAndroid), textType: .paragraph))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenMagnificationIntroductionHeader), textType: .header))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenMagnificationIntroduction), textType: .paragraph))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenMagnificationScreenTools), textType: .boldText))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenMagnificationScreenToolsiOS), textType: .paragraph))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenMagnificationScreenToolsAndroid), textType: .paragraph))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenMagnificationTools), textType: .boldText))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenMagnificationToolsiOS), textType: .paragraph))
        introText.append(textStyle(text: L(.accessibilityIntroductionScreenMagnificationToolsAndroid), textType: .paragraph))
        
        return introText
    }
}

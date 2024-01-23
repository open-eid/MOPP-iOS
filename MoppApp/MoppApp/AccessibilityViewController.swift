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

import UIKit

class AccessibilityViewController : MoppViewController, UITextViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var closeButton: UIButton!

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var contentView: UIView!

    @IBAction func dismissAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = L(.accessibilityIntroductionTitle)
        
        var previousLabel: UILabel?
        
        let accessibilityLabels = accessibilityIntroductionText()
        for label in accessibilityLabels {
            label.numberOfLines = 0
            label.textAlignment = .left
            label.translatesAutoresizingMaskIntoConstraints = false
            
            contentView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
                label.topAnchor.constraint(equalTo: previousLabel?.bottomAnchor ?? contentView.topAnchor, constant: 20)
            ])
            
            previousLabel = label
        }

        if let lastLabel = accessibilityLabels.last {
            NSLayoutConstraint.activate([
                lastLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
            ])
        }
        
        closeButton.accessibilityLabel = L(.closeButton)
        closeButton.accessibilityUserInputLabels = [L(.voiceControlClose)]
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
            return NSMutableAttributedString(string: "\n\(text)", attributes: attributes)
        case .paragraph:
            attributes = [
                NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .body),
                NSAttributedString.Key.foregroundColor : UIColor.moppTitle
            ]
            let linkAttributes: [NSAttributedString.Key : Any] = [
                NSAttributedString.Key.foregroundColor: UIColor.link,
                NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue
            ]
            
            do {
                let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let mutableAttributedString = NSMutableAttributedString(string: text, attributes: attributes)
                        mutableAttributedString.addAttributes(linkAttributes, range: NSRange(range, in: text))
                        
                        return NSAttributedString(attributedString: mutableAttributedString)
                    }
                }
            } catch let error {
                print("Error creating link attributes: \(error.localizedDescription)")
            }
            break
        case .boldText:
            if let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSymbolicTraits(.traitBold) {
                attributes = [
                    NSAttributedString.Key.font : UIFont(descriptor: fontDescriptor, size: fontDescriptor.pointSize),
                    NSAttributedString.Key.foregroundColor : UIColor.moppTitle]
            } else {
                attributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.moppTitle]
            }
        }
        
        return NSMutableAttributedString(string: "\(text)", attributes: attributes)
    }
    
    private func setupLabelWithAccessibilityTraits(attributedString: NSAttributedString, traits: UIAccessibilityTraits) -> UILabel {
        let label = ScaledLabel()
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLinkTap(_:))))
        label.attributedText = attributedString
        label.accessibilityTraits = traits
        label.accessibilityLabel = attributedString.string
        return label
    }
    
    private func accessibilityIntroductionText() -> [UILabel] {
        var labels: [UILabel] = []
        let texts: [(String, AccessibilityViewTextType)] = [
            (L(.accessibilityIntroduction), .paragraph),
            (L(.accessibilityLink), .paragraph),
            (L(.accessibilityIntroduction2), .paragraph),
            (L(.accessibilityIntroductionScreenReaderHeader), .header),
            (L(.accessibilityIntroductionScreenReaderIntroduction), .paragraph),
            (L(.accessibilityIntroductionScreenReaderIntroduction2), .paragraph),
            (L(.accessibilityIntroductionScreenReaderIntroductionApps), .boldText),
            (L(.accessibilityIntroductionScreenReaderIntroductioniOS), .paragraph),
            (L(.accessibilityIntroductionScreenReaderIntroductionAndroid), .paragraph),
            (L(.accessibilityIntroductionScreenMagnificationIntroductionHeader), .header),
            (L(.accessibilityIntroductionScreenMagnificationIntroduction), .paragraph),
            (L(.accessibilityIntroductionScreenMagnificationScreenTools), .boldText),
            (L(.accessibilityIntroductionScreenMagnificationScreenToolsiOS), .paragraph),
            (L(.accessibilityIntroductionScreenMagnificationScreenToolsAndroid), .paragraph),
            (L(.accessibilityIntroductionScreenMagnificationTools), .boldText),
            (L(.accessibilityIntroductionScreenMagnificationToolsiOS), .paragraph),
            (L(.accessibilityIntroductionScreenMagnificationToolsAndroid), .paragraph)
        ]
        
        for (text, textType) in texts {
            let attributedString = textStyle(text: text, textType: textType)
            var traits: UIAccessibilityTraits = []
            
            if textType == .header {
                traits.insert(UIAccessibilityTraits.header)
            }
            
            let label = setupLabelWithAccessibilityTraits(attributedString: attributedString, traits: traits)
            labels.append(label)
        }
        
        return labels
    }
    
    @objc func handleLinkTap(_ sender: UITapGestureRecognizer) {
        if let label = sender.view as? UILabel, let text = label.text {
            let attributedString = NSMutableAttributedString(string: text)

            let firstLink = attributedString.string.getFirstLinkInMessage()

            if let link = firstLink, !link.isEmpty, let url = URL(string: link) {
                UIApplication.shared.open(url)
            }
        }
    }
}

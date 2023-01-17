//
//  UITextView+Additions.swift
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

extension UITextView {
    func setLinkedText(_ text: String, withLinks linkStrings: [AnyHashable: Any]) {
        setLinkedText(text, withLinks: linkStrings, font: self.font!)
    }

    func setLinkedText(_ text: String, withLinks linkStrings: [AnyHashable: Any], font: UIFont?) {
        let attributedString = NSMutableAttributedString(string: text)
        let paths = linkStrings.keys
        for path in paths {
            let link = linkStrings[path] as? String
            attributedString.addAttribute(.link, value: path, range: (text as NSString).range(of: link!))
        }
        let defaultFont = UIFont.systemFont(ofSize: 14)
        attributedString.addAttribute(.font, value: font ?? defaultFont, range: NSRange(location: 0, length: (text.count)))
        attributedText = attributedString
        isSelectable = true
        isEditable = false
    }
}

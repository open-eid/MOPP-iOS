//
//  AccessibilityUtil.swift
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

class AccessibilityUtil {
    static func setAccessibilityElementsInStackView(stackView: UIStackView, isAccessibilityElement: Bool) {
        for subview in stackView.arrangedSubviews {
            subview.isAccessibilityElement = isAccessibilityElement
        }
    }
    
    // Adjust spacing between addressee and "Add" buttons
    // Adjust so that the spacing is not too big and also don't overlap each other when font size changes
    static func adjustSpacing(preferredContentSizeCategory: UIContentSizeCategory, stackView: UIStackView) {
        switch preferredContentSizeCategory {
        case .extraSmall, .small, .medium, .large, .extraLarge, .extraExtraLarge:
            stackView.spacing = -120
            break
        default:
            stackView.spacing = 0
            break
        }
    }
}

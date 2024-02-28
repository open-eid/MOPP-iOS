//
//  FontUtil.swift
//  MoppApp
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

struct FontUtil {
    
    static func scaleFont(font: UIFont) -> UIFont {
        return UIFontMetrics.default.scaledFont(for: font)
    }
    
    static func boldFont(font: UIFont) -> UIFont {
        if let boldFont = UIFont(name: "Roboto-Bold", size: font.pointSize) {
            return UIFontMetrics.default.scaledFont(for: boldFont)
        }
        
        return font
    }
    
    static func mediumFont(font: UIFont) -> UIFont {
        if let mediumFont = UIFont(name: "Roboto-Medium", size: font.pointSize) {
            return UIFontMetrics.default.scaledFont(for: mediumFont)
        }
        
        return font
    }
}

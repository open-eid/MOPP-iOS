//
//  UIFont+Additions.swift
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
import UIKit


enum MoppFontName : String {
    case light          = "Roboto-Light"
    case lightItalic    = "Roboto-LightItalic"
    case regular        = "Roboto-Regular"
    case italic         = "Roboto-Italic"
    case medium         = "Roboto-Medium"
    case bold           = "Roboto-Bold"
    case boldItalic     = "Roboto-BoldItalic"
    case allCapsRegular        = "RobotoCondensed-Regular"
    case allCapsItalic         = "RobotoCondensed-Italic"
    case allCapsBold           = "RobotoCondensed-Bold"
    case allCapsBoldItalic     = "RobotoCondensed-BoldItalic"
    case allCapsLight          = "RobotoCondensed-Light"
    case allCapsLightItalic    = "RobotoCondensed-LightItalic"
}

extension UIFont {
    class var moppLargeMedium: UIFont {
        let mediumFont = UIFont(name: MoppFontName.medium.rawValue, size: 16)!
        return UIFontMetrics(forTextStyle: .headline).scaledFont(for: mediumFont)
    }
    
    class var moppMediumBold: UIFont {
        let boldFont = UIFont(name: MoppFontName.bold.rawValue, size: 16)!
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: boldFont)
    }
    
    class var moppMediumRegular: UIFont {
        let regularFont = UIFont(name: MoppFontName.regular.rawValue, size: 15)!
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: regularFont)
    }
    
    class var moppSmallerRegular: UIFont {
        let regularFont = UIFont(name: MoppFontName.regular.rawValue, size: 13)!
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: regularFont)
    }
    
    class var moppSmallRegular: UIFont {
        let descriptiveTextFont = UIFont(name: MoppFontName.regular.rawValue, size: 10)!
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: descriptiveTextFont)
    }
    
    class var moppSmallCapsRegular: UIFont {
        let allCapsRegularFont = UIFont(name: MoppFontName.allCapsRegular.rawValue, size: 10)!
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: allCapsRegularFont)
    }
    
    class var moppMediumCapsRegular: UIFont {
        let allCapsRegularFont = UIFont(name: MoppFontName.allCapsRegular.rawValue, size: 14)!
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: allCapsRegularFont)
    }

    class var moppLargerMedium: UIFont {
        let mediumFont = UIFont(name: MoppFontName.medium.rawValue, size: 17)!
        return UIFontMetrics(forTextStyle: .headline).scaledFont(for: mediumFont)
    }

    class var moppUltraLargeMedium: UIFont {
        let mediumFont = UIFont(name: MoppFontName.medium.rawValue, size: 20)!
        return UIFontMetrics(forTextStyle: .headline).scaledFont(for: mediumFont)
    }
}

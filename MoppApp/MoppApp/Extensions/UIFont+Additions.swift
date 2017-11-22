//
//  UIFont+Additions.swift
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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
    var moppHeadline: UIFont {
        return UIFont(name: MoppFontName.medium.rawValue, size: 16)!
    }
    
    var moppText: UIFont {
        return UIFont(name: MoppFontName.regular.rawValue, size: 13)!
    }
    
    var moppDescriptiveText: UIFont {
        return UIFont(name: MoppFontName.regular.rawValue, size: 10)!
    }
    
    var moppMainMenu: UIFont {
        return UIFont(name: MoppFontName.allCapsRegular.rawValue, size: 10)!
    }
    
    var moppButtonTitle: UIFont {
        return UIFont(name: MoppFontName.allCapsRegular.rawValue, size: 14)!
    }
    
    var moppSmallButtonTitle: UIFont {
        return UIFont(name: MoppFontName.allCapsRegular.rawValue, size: 10)!
    }
    
    var moppDatafieldLabel: UIFont {
        return UIFont(name: MoppFontName.allCapsRegular.rawValue, size: 10)!
    }
    
    var moppAccordionLabel: UIFont {
        return UIFont(name: MoppFontName.allCapsRegular.rawValue, size: 13)!
    }

}

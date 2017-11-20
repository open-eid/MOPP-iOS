//
//  UIFont+Additions.swift
//  MoppApp
//
//  Created by Sander Hunt on 20/11/2017.
//  Copyright © 2017 Riigi Infosüsteemide Amet. All rights reserved.
//

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

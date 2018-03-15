//
//  UIColor+Additions.swift
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

enum MoppColorHexCode : String {
    case title              = "041E42"   //  Dark blue
    case base               = "006EB5"   //  Blue
    case text               = "363739"   //  Dark gray
    case label              = "75787B"   //  Medium gray
    case descriptiveText    = "B1B3B3"   //  Gray
    case baseBackground     = "F4F5F6"   //  Light gray
    case backgroundLine     = "DEE4E9"   //  Light blue
    case contentLine        = "F0F0EF"   //  Light beige
    case emblem             = "998B66"   //  Dark beige
    case error              = "981E32"   //  Red
    case success            = "8CC368"   //  Green
    case containerWarning   = "FFEABE"   //  Yellow
    case mainMenu           = "023664"   //  Dark blue
}

extension UIColor {

    class func fromHexString(_ hexString: String) -> UIColor {
        var rgbValue: UInt32 = 0
        
        let scanner = Scanner(string: hexString)
            scanner.scanHexInt32(&rgbValue)
        
        return UIColor(
            red: (CGFloat)((rgbValue & 0xff0000) >> 16) / 255.0,
            green: (CGFloat)((rgbValue & 0xff00) >> 8) / 255.0,
            blue: (CGFloat)(rgbValue & 0xff) / 255.0,
            alpha: 1.0)
    }

    class func fromHexString(_ hexString: String, alpha: CGFloat) -> UIColor {
        var rgbValue: UInt32 = 0
        
        let scanner = Scanner(string: hexString)
            scanner.scanHexInt32(&rgbValue)
        
        return UIColor(
            red: (CGFloat)((rgbValue & 0xff0000) >> 16) / 255.0,
            green: (CGFloat)((rgbValue & 0xff00) >> 8) / 255.0,
            blue: (CGFloat)(rgbValue & 0xff) / 255.0,
            alpha: alpha)
    }

    class var moppTitle: UIColor {
        return UIColor.fromHexString(MoppColorHexCode.title.rawValue)
    }

    class var moppBase: UIColor {
        return UIColor.fromHexString(MoppColorHexCode.base.rawValue)
    }

    class var moppText: UIColor {
        return UIColor.fromHexString(MoppColorHexCode.text.rawValue)
    }

    class var moppLabel: UIColor {
        return UIColor.fromHexString(MoppColorHexCode.label.rawValue)
    }

    class var moppDescriptiveText: UIColor {
        return UIColor.fromHexString(MoppColorHexCode.descriptiveText.rawValue)
    }

    class var moppBaseBackground: UIColor {
        return UIColor.fromHexString(MoppColorHexCode.baseBackground.rawValue)
    }

    class var moppBackgroundLine: UIColor {
        return UIColor.fromHexString(MoppColorHexCode.backgroundLine.rawValue)
    }

    class var moppContentLine: UIColor {
        return UIColor.fromHexString(MoppColorHexCode.contentLine.rawValue)
    }

    class var moppEmblem: UIColor {
        return UIColor.fromHexString(MoppColorHexCode.emblem.rawValue)
    }

    class var moppError: UIColor {
        return UIColor.fromHexString(MoppColorHexCode.error.rawValue)
    }

    class var moppSuccess: UIColor {
        return UIColor.fromHexString(MoppColorHexCode.success.rawValue)
    }

    class var moppContainerWarning: UIColor {
        return UIColor.fromHexString(MoppColorHexCode.containerWarning.rawValue)
    }
    
    class var moppMainMenu: UIColor {
        return UIColor.fromHexString(MoppColorHexCode.mainMenu.rawValue)
    }

    class var moppSelectedTabBarItem: UIColor {
        return UIColor.moppBaseBackground
    }

    class var moppUnselectedTabBarItemAlpha: CGFloat {
        return 0.5
    }
    
    class var moppUnselectedTabBarItem: UIColor {
        return UIColor.moppSelectedTabBarItem.withAlphaComponent(UIColor.moppUnselectedTabBarItemAlpha)
    }
}

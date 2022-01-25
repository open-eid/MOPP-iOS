//
//  Utils.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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

struct ScreenSize
{
    static let SCREEN_WIDTH         = UIScreen.main.bounds.size.width
    static let SCREEN_HEIGHT        = UIScreen.main.bounds.size.height
    static let SCREEN_MAX_LENGTH    = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH    = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType
{
    static let IS_IPHONE_4_OR_LESS  = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
    static let IS_IPHONE_5          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
    static let IS_IPHONE_6          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
    static let IS_IPHONE_6_OR_MORE  = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH >= 667.0
    static let IS_IPHONE_6P         = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
    static let IS_IPAD              = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH == 1024.0
    static let IS_IPAD_PRO          = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH == 1366.0
}

func isDeviceOrientationLandscape() -> Bool {
    if UIDevice.current.orientation.isFlat || !UIDevice.current.orientation.isValidInterfaceOrientation {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation.isLandscape ?? false
        } else {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
    
    return UIDevice.current.orientation.isLandscape
}

func MSLog(_ format: String, _ arguments: Any...) {
    NSLog(format, arguments)
}

let kDefaultLanguageID = "en"

// Fixme: couldn't get around erroneous output using CVarArg... or Any... as 'arguments' type
func L(_ key: LocKey, _ arguments: [CVarArg] = []) -> String {
    let languageId = DefaultsHelper.moppLanguageID
    let path = Bundle.main.path(forResource: languageId, ofType: "lproj", inDirectory: String()) ??
        Bundle.main.path(forResource: kDefaultLanguageID, ofType: "lproj", inDirectory: String())
    guard let bundlePath = path else { return String() }
    let bundle = Bundle(path: bundlePath)
    let format = bundle?.localizedString(forKey: key.rawValue, value: nil, table: nil)
    return String(format: format!, arguments: arguments)
}

func MoppLib_LocalizedString(_ key: String,_ arguments: [CVarArg] = []) -> String {
    let languageId = DefaultsHelper.moppLanguageID
    let moppLibBundlePath = Bundle(identifier: "mobi.lab.MoppLib")?.path(forResource: languageId, ofType: "lproj")
    guard let strongMoppLibBundlePath = moppLibBundlePath else { return String()}
    let bundle = Bundle(path: strongMoppLibBundlePath)
    let format = bundle?.localizedString(forKey: key, value: String(), table: nil)
    guard let strongFormat = format else { return String()}
    return String(format: strongFormat, arguments: arguments)
}

func SkSigningLib_LocalizedString(_ key: String,_ arguments: [CVarArg] = []) -> String {
    let languageId = DefaultsHelper.moppLanguageID
    let moppLibBundlePath = Bundle(identifier: "ee.ria.digidoc.SkSigningLib")?.path(forResource: languageId, ofType: "lproj")
    guard let strongMoppLibBundlePath = moppLibBundlePath else { return String()}
    let bundle = Bundle(path: strongMoppLibBundlePath)
    let format = bundle?.localizedString(forKey: key, value: String(), table: nil)
    guard let strongFormat = format else { return String()}
    return String(format: strongFormat, arguments: arguments)
}

func formatString(text: String, additionalText: String? = nil) -> String {
    if (additionalText != nil) {
        return "\(text) \(additionalText!)"
    } else {
        return text
    }
}

func setTabAccessibilityLabel(isTabSelected: Bool, tabName: String, positionInRow: String, viewCount: String) -> String {
    if isTabSelected {
        return "\(L(.tabSelected, [tabName, positionInRow, String(viewCount)]))"
    } else {
        return "\(L(.tabUnselected, [tabName, positionInRow, String(viewCount)]))"
    }
}

func countryCodePrefill(textField: UITextField, countryCode: String) -> Void {
    if (textField.text.isNilOrEmpty) {
        textField.text = countryCode
    }
}

func singleCharacterToUnicodeScalar(character: Character) -> Unicode.Scalar {
    let unicodeScalars: Character.UnicodeScalarView = character.unicodeScalars
    guard unicodeScalars.count == 1, let firstUnicodeScalar = unicodeScalars.first else {
        NSLog("Invalid character or not a single character")
        return Unicode.Scalar(0)
    }
    return UnicodeScalar(firstUnicodeScalar)
}

func isNonDefaultPreferredContentSizeCategory() -> Bool {
    return UIApplication.shared.preferredContentSizeCategory != .large
}

func isNonDefaultPreferredContentSizeCategorySmaller() -> Bool {
    return UIApplication.shared.preferredContentSizeCategory < .large
}

func isNonDefaultPreferredContentSizeCategoryBigger() -> Bool {
    return UIApplication.shared.preferredContentSizeCategory > .large
}

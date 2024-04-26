//
//  DefaultsHelper.swift
//  MoppApp
//
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

let ContainerFormatAdoc = "adoc"
let ContainerFormatBdoc = "bdoc"
let ContainerFormatEdoc = "edoc"
let ContainerFormatDdoc = "ddoc"
let ContainerFormatAsice = "asice"
let ContainerFormatAsiceShort = "sce"
let ContainerFormatAsics = "asics"
let ContainerFormatAsicsShort = "scs"
let ContainerFormatPDF  = "pdf"
let ContainerFormatCdoc = "cdoc"
let ContainerFormatP12d = "p12d"
let FileFormatXml = "xml"

let ContainerFormatAsiceMimetype = "application/vnd.etsi.asic-e+zip"
let ContainerFormatAsicsMimetype = "application/vnd.etsi.asic-s+zip"
let ContainerFormatDdocMimetype = "application/x-ddoc"
let ContainerFormatCdocMimetype = "application/x-cdoc"
let ContainerFormatAdocMimetype = "application/vnd.lt.archyvai.adoc-2008"

let DefaultContainerFormat = ContainerFormatAsice

let CrashlyticsAlwaysSend = "Always"
let CrashlyticsNeverSend = "Never"
let CrashlyticsDefault = "Default"
// Keys
fileprivate let kSignMethodKey = "kSignMethodKey"
fileprivate let kPhoneNumberKey = "kPhoneNumberKey"
fileprivate let kIDCodeKey = "kIDCodeKey"
fileprivate let kMobileIdRememberMeKey = "kMobileIdRememberMeKey"
fileprivate let kRPUuidKey = "kRPUuidKey"
fileprivate let kSIDIDCodeKey = "kSIDIDCodeKey"
fileprivate let kSIDCountryKey = "kSIDCountryKey"
fileprivate let kSmartIdRememberMeKey = "kSmartIdRememberMeKey"
fileprivate let kNFCRememberMeKey = "kNFCRememberMeKey"

fileprivate let kRoleNamesKey = "kRoleNamesKey"
fileprivate let kRoleCityKey = "kRoleCityKey"
fileprivate let kRoleStateKey = "kRoleStateKey"
fileprivate let kRoleCountryKey = "kRoleCountryKey"
fileprivate let kRoleZipKey = "kRoleZipKey"

fileprivate let kTimestampUrlKey = "kTimestampUrlKey"
fileprivate let kSettingsDefaultSwitchKey = "kSettingsDefaultSwitchKey"
fileprivate let kCrashReportSettingKey = "kCrashReportSettingKey"
fileprivate let kPreviousPreferredLanguage = "kPreviousPreferredLanguage"
fileprivate let kMoppLanguage = "kMoppLanguage"
fileprivate let kIsTimestampedDdoc = "kIsTimestampedDdoc"
fileprivate let kIsFileLoggingEnabled = "kIsFileLoggingEnabled"
fileprivate let kIsFileLoggingRunning = "kIsFileLoggingRunning"
fileprivate let kTSAFileCertName = "kTSAFileCertName"
fileprivate let kIsRoleAndAddressEnabled = "kIsRoleAndAddressEnabled"
fileprivate let kSivaAccessState = "kSivaAccessState"
fileprivate let kSivaUrl = "kSivaUrl"
fileprivate let kSivaFileCertName = "kSivaFileCertName"

class DefaultsHelper
{
    static func setDefaultKeys() {
        UserDefaults.standard.register(
            defaults: [
                kSettingsDefaultSwitchKey: true,
                kMobileIdRememberMeKey: true,
                kSmartIdRememberMeKey: true,
                kNFCRememberMeKey: true
            ]
        )
    }
    
    class var signMethod: String {
        set {
            UserDefaults.standard.set(newValue, forKey: kSignMethodKey)
        }
        get {
            return UserDefaults.standard.value(forKey: kSignMethodKey) as? String ?? "mobileID"
        }
    }

    class var phoneNumber: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: kPhoneNumberKey)
        }
        get {
            return UserDefaults.standard.value(forKey: kPhoneNumberKey) as? String
        }
    }

    class var idCode: String {
        set {
            UserDefaults.standard.set(newValue, forKey: kIDCodeKey)
        }
        get {
            return (UserDefaults.standard.value(forKey: kIDCodeKey) as? String) ?? String()
        }
    }
    
    class var mobileIdRememberMe: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: kMobileIdRememberMeKey)
        }
        get {
            return (UserDefaults.standard.bool(forKey: kMobileIdRememberMeKey))
        }
    }

    class var rpUuid: String {
        set {
            UserDefaults.standard.set(newValue, forKey: kRPUuidKey)
        }
        get {
            return (UserDefaults.standard.value(forKey: kRPUuidKey) as? String) ?? String()
        }
    }

    class var sidCountry: String {
        set {
            UserDefaults.standard.set(newValue, forKey: kSIDCountryKey)
        }
        get {
            return (UserDefaults.standard.value(forKey: kSIDCountryKey) as? String) ?? String()
        }
    }

    class var sidIdCode: String {
        set {
            UserDefaults.standard.set(newValue, forKey: kSIDIDCodeKey)
        }
        get {
            return (UserDefaults.standard.value(forKey: kSIDIDCodeKey) as? String) ?? String()
        }
    }
    
    class var smartIdRememberMe: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: kSmartIdRememberMeKey)
        }
        get {
            return (UserDefaults.standard.bool(forKey: kSmartIdRememberMeKey))
        }
    }

    class var timestampUrl: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: kTimestampUrlKey)
        }
        get {
            return UserDefaults.standard.value(forKey: kTimestampUrlKey) as? String
        }
    }
    
    class var defaultSettingsSwitch: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: kSettingsDefaultSwitchKey)
        }
        get {
            return UserDefaults.standard.bool(forKey: kSettingsDefaultSwitchKey) as Bool
        }
    }

    class var crashReportSetting: String {
        set {
            UserDefaults.standard.set(newValue, forKey: kCrashReportSettingKey)
        }
        get {
            return (UserDefaults.standard.value(forKey: kCrashReportSettingKey) as? String) ?? String()
        }
    }

    class var moppLanguageID: String {
        get {
            var languageId: String! = UserDefaults.standard.value(forKey: kMoppLanguage) as? String
            
            if languageId == nil {
                languageId = Locale.preferredLanguages.first?.lowercased().substr(offset: 0, count: 2) ?? kDefaultLanguageID
                UserDefaults.standard.set(languageId, forKey: kMoppLanguage)
                UserDefaults.standard.synchronize()
            }
        
            return languageId ?? kDefaultLanguageID
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kMoppLanguage)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var isTimestampedDdoc: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: kIsTimestampedDdoc)
        }
        get {
            return UserDefaults.standard.bool(forKey: kIsTimestampedDdoc)
        }
    }
    
    class var isFileLoggingEnabled: Bool {
        set {
            DispatchQueue.main.async {
                UserDefaults.standard.set(newValue, forKey: kIsFileLoggingEnabled)
            }
        }
        get {
            return UserDefaults.standard.bool(forKey: kIsFileLoggingEnabled)
        }
    }
    
    class var isFileLoggingRunning: Bool {
        set {
            DispatchQueue.main.async {
                UserDefaults.standard.set(newValue, forKey: kIsFileLoggingRunning)
            }
        }
        get {
            return UserDefaults.standard.bool(forKey: kIsFileLoggingRunning)
        }
    }
    
    class var tsaCertFileName: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: kTSAFileCertName)
        }
        get {
            return UserDefaults.standard.value(forKey: kTSAFileCertName) as? String
        }
    }

    class var isRoleAndAddressEnabled: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: kIsRoleAndAddressEnabled)
        }
        get {
            return UserDefaults.standard.bool(forKey: kIsRoleAndAddressEnabled)
        }
    }
    
    class var roleNames: [String] {
        set {
            UserDefaults.standard.set(newValue, forKey: kRoleNamesKey)
        }
        get {
            return (UserDefaults.standard.value(forKey: kRoleNamesKey) as? [String]) ?? [String]()
        }
    }
    
    class var roleCity: String {
        set {
            UserDefaults.standard.set(newValue, forKey: kRoleCityKey)
        }
        get {
            return (UserDefaults.standard.value(forKey: kRoleCityKey) as? String) ?? String()
        }
    }
    
    class var roleState: String {
        set {
            UserDefaults.standard.set(newValue, forKey: kRoleStateKey)
        }
        get {
            return (UserDefaults.standard.value(forKey: kRoleStateKey) as? String) ?? String()
        }
    }
    
    class var roleCountry: String {
        set {
            UserDefaults.standard.set(newValue, forKey: kRoleCountryKey)
        }
        get {
            return (UserDefaults.standard.value(forKey: kRoleCountryKey) as? String) ?? String()
        }
    }
    
    class var roleZip: String {
        set {
            UserDefaults.standard.set(newValue, forKey: kRoleZipKey)
        }
        get {
            return (UserDefaults.standard.value(forKey: kRoleZipKey) as? String) ?? String()
        }
    }

    class var sivaAccessState: SivaAccess {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: kSivaAccessState)
        }
        get {
            return SivaAccess(rawValue: UserDefaults.standard.value(forKey: kSivaAccessState) as? String ?? "") ?? .defaultAccess
        }
    }

    class var sivaUrl: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: kSivaUrl)
        }
        get {
            return UserDefaults.standard.value(forKey: kSivaUrl) as? String
        }
    }

    class var sivaCertFileName: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: kSivaFileCertName)
        }
        get {
            return UserDefaults.standard.value(forKey: kSivaFileCertName) as? String
        }
    }
    
    class var nfcRememberMe: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: kNFCRememberMeKey)
        }
        get {
            return (UserDefaults.standard.bool(forKey: kNFCRememberMeKey))
        }
    }
}

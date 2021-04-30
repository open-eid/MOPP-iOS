//
//  DefaultsHelper.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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
let ContainerFormatAscis = "asics"
let ContainerFormatAsicsShort = "scs"
let ContainerFormatPDF  = "pdf"
let ContainerFormatCdoc = "cdoc"
let FileFormatXml = "xml"

let DefaultContainerFormat = ContainerFormatAsice

let CrashlyticsAlwaysSend = "Always"
let CrashlyticsNeverSend = "Never"
let CrashlyticsDefault = "Default"
// Keys
fileprivate let kSignMethodKey = "kSignMethodKey"
fileprivate let kPhoneNumberKey = "kPhoneNumberKey"
fileprivate let kIDCodeKey = "kIDCodeKey"
fileprivate let kRPUuidKey = "kRPUuidKey"
fileprivate let kSIDIDCodeKey = "kSIDIDCodeKey"
fileprivate let kSIDCountryKey = "kSIDCountryKey"
fileprivate let kTimestampUrlKey = "kTimestampUrlKey"
fileprivate let kCrashReportSettingKey = "kCrashReportSettingKey"
fileprivate let kPreviousPreferredLanguage = "kPreviousPreferredLanguage"
fileprivate let kMoppLanguage = "kMoppLanguage"
fileprivate let kHideShareContainerDialog = "kHideShareContainerDialog"

class DefaultsHelper
{
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

    class var timestampUrl: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: kTimestampUrlKey)
        }
        get {
            return UserDefaults.standard.value(forKey: kTimestampUrlKey) as? String
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
    
    class var hideShareContainerDialog: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: kHideShareContainerDialog)
        }
        get {
            return UserDefaults.standard.bool(forKey: kHideShareContainerDialog)
        }
    }

}

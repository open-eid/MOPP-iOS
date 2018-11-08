//
//  DefaultsHelper.swift
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
fileprivate let DefaultTimestampUrl = "http://dd-at.ria.ee/tsa"

let CrashlyticsAlwaysSend = "Always"
let CrashlyticsNeverSend = "Never"
let CrashlyticsDefault = "Default"
// Keys
fileprivate let kPhoneNumberKey = "kPhoneNumberKey"
fileprivate let kIDCodeKey = "kIDCodeKey"
fileprivate let kTimestampUrlKey = "kTimestampUrlKey"
fileprivate let kCrashReportSettingKey = "kCrashReportSettingKey"
fileprivate let kPreviousPreferredLanguage = "kPreviousPreferredLanguage"
fileprivate let kMoppLanguage = "kMoppLanguage"

class DefaultsHelper
{
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
    
    class var timestampUrl: String {
        set {
            UserDefaults.standard.set(newValue, forKey: kTimestampUrlKey)
        }
        get {
            guard UserDefaults.standard.object(forKey: kTimestampUrlKey) != nil else {
                UserDefaults.standard.set(DefaultTimestampUrl, forKey: kTimestampUrlKey)
                return DefaultTimestampUrl
            }
            return (UserDefaults.standard.value(forKey: kTimestampUrlKey) as? String) ?? String()
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

}

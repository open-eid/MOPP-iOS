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

let DefaultContainerFormat = ContainerFormatBdoc

let CrashlyticsAlwaysSend = "Always"
let CrashlyticsNeverSend = "Never"
let CrashlyticsDefault = "Default"
// Keys
let kNewContainerFormatKey = "kNewContainerFormatKey"
let kPhoneNumberKey = "kPhoneNumberKey"
let kIDCodeKey = "kIDCodeKey"
let kCrashReportSettingKey = "kCrashReportSettingKey"
let kPreviousPreferredLanguage = "kPreviousPreferredLanguage"
let kMoppLanguage = "kMoppLanguage"

class DefaultsHelper
{
    // New container format
    class var newContainerFormat: String {
        set {
            UserDefaults.standard.set(newValue, forKey: kNewContainerFormatKey)
        }
        get {
            return (UserDefaults.standard.value(forKey: kNewContainerFormatKey) as? String) ?? String()
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
            // Force app language to system language only if it has changed or first run
            
            let preferredLanguage = Locale.preferredLanguages.first?.lowercased().substr(offset: 0, count: 2) ?? kDefaultLanguageID
            let previousPreferredLanguage: String! = UserDefaults.standard.value(forKey: kPreviousPreferredLanguage) as? String
            
            if previousPreferredLanguage == nil || preferredLanguage != previousPreferredLanguage {
                UserDefaults.standard.set(preferredLanguage, forKey: kMoppLanguage)
                UserDefaults.standard.set(preferredLanguage, forKey: kPreviousPreferredLanguage)
                UserDefaults.standard.synchronize()
            }
        
            var languageId: String! = UserDefaults.standard.value(forKey: kMoppLanguage) as? String
            if languageId == nil {
                languageId = preferredLanguage
                UserDefaults.standard.set(languageId, forKey: kMoppLanguage)
                UserDefaults.standard.synchronize()
            }
            return languageId
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kMoppLanguage)
            UserDefaults.standard.synchronize()
        }
    }

}

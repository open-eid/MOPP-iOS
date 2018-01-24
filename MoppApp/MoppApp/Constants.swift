//
//  Constants.swift
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


let kKeyContainer = "container"
let kKeyContainerNew = "containerNew"
let kKeyContainerOld = "containerOld"
let kCreateSignatureResponseKey = "MobileCreateSignatureResponse"
let kNewContainerKey = "MoppLibContainerNew"
let kOldContainerKey = "MoppLibContainerOld"
let kErrorKey = "Error"
let kErrorMessage = "Error message"
let kKeyImportedFilePaths = "importedFilePaths"
let kKeyFileImportIntent = "fileImportIntent"

extension Notification.Name {
    static let containerChangedNotificationName = Notification.Name("Notification - container changed")
    static let settingsChangedNotificationName = Notification.Name("Notification - settigns changed")
    static let willEnterForegroundNotificationName = Notification.Name("Notification - will enter foreground")
    static let createSignatureNotificationName = Notification.Name("MobileCreateSignatureNotification")
    static let signatureAddedToContainerNotificationName = Notification.Name("SignatureAddedToContainer")
    static let errorNotificationName = Notification.Name("ErrorNotification")
    static let openContainerNotificationName = Notification.Name("OpenContainerNotificationName")
    static let signatureCreatedFinishedNotificationName = Notification.Name("SignatureCreatedFinishedNotificationName")
    static let filesImportedNotificationName = Notification.Name("FilesImportedNotificationName")
    static let startImportingFilesWithDocumentPickerNotificationName = Notification.Name("StartImportingFilesNotificationName")
}

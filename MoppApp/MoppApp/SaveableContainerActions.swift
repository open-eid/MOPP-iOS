//
//  SaveableContainerActions.swift
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

class SaveableContainer {
    
    var signingContainerPath: String = ""
    var cryptoContainer: CryptoContainer?
    
    init(signingContainerPath containerPath: String) {
        self.signingContainerPath = containerPath
    }
    
    init(signingContainerPath containerPath: String, cryptoContainer container: CryptoContainer?) {
        self.signingContainerPath = containerPath
        self.cryptoContainer = container
    }
    
    func saveDataFile(name: String?, completionHandler: @escaping (String, Bool) -> Void) {
        
        guard let name = name, !name.isEmpty, signingContainerFileExists(name: name) || cryptoContainerExists(name: name) else {
            return completionHandler("", false)
        }
        
        MoppFileManager.shared.saveFile(containerPath: self.signingContainerPath, fileName: name, completionHandler: { (isSaved: Bool, tempSavedFileLocation: String?) in
            if isSaved {
                guard let tempSavedFileLocation = tempSavedFileLocation, MoppFileManager.shared.fileExists(tempSavedFileLocation) else {
                    NSLog("Failed to get saved temp file location or file does not exist")
                    return completionHandler("", false)
                }
                
                NSLog("Exporting to user chosen location")
                
                completionHandler(tempSavedFileLocation, true)
            } else {
                NSLog("Failed to save \(name) to 'Saved Files' directory")
                completionHandler("", false)
            }
        })
    }
    
    static func isFileSaved(urls: [URL]) -> Bool {
        if !urls.isEmpty {
            return true
        }
        
        return false
    }
    
    private func signingContainerFileExists(name: String?) -> Bool {
        guard name != nil, !signingContainerPath.isEmpty, MoppFileManager.shared.fileExists(signingContainerPath) else {
            NSLog("Failed to get filename or file does not exist in container");
            return false
        }
        
        return true
    }
    
    private func cryptoContainerExists(name: String?) -> Bool {
        guard name != nil, cryptoContainer != nil else {
            NSLog("Failed to get filename or file does not exist in container");
            return false
        }
        
        return true
    }
}

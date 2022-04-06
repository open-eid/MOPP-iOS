//
//  ContainerRemovalActions.swift
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

class ContainerRemovalActions {
    
    public static let shared: ContainerRemovalActions = ContainerRemovalActions()
    
    func removeAsicContainer(containerPath: String?) -> Bool {
        guard let containerPath = containerPath else {
            printLog("Container not found")
            return false
        }
        
        MoppFileManager.shared.removeFile(withPath: containerPath)
        return !MoppFileManager.shared.fileExists(containerPath)
    }
    
    func removeCdocContainer(cryptoContainer: CryptoContainer?) -> Bool {
        guard let cryptoContainer: CryptoContainer = cryptoContainer else {
            printLog("Container not found")
            return false
        }
        
        guard cryptoContainer.dataFiles.count > 0 else {
            printLog("No crypto container datafiles found")
            return false
        }
        
        cryptoContainer.dataFiles.removeObject(at: 0)
        
        return cryptoContainer.dataFiles.count == 0
    }
    
}

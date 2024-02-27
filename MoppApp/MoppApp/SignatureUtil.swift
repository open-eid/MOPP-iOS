//
//  SignatureUtil.swift
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

import Foundation
import MoppLib

class SignatureUtil {

    static func isCades(signatures: [Any]) -> Bool {
        for signature in signatures {
            guard let sig = signature as? MoppLibSignature else { return false }
            
            return sig.signatureFormat.lowercased().contains("cades")
        }
        
        return false
    }
    
    static func getSignatures(filePath: URL) -> [Any] {
        do {
            let container = try MoppLibContainerActions.sharedInstance().openContainer(withPath: filePath.path)
            
            return container.signatures
        } catch let error {
            guard let nsError = error as NSError? else { return [] }
            printLog("Error getting signatures: \(nsError.localizedDescription)")
            return []
        }
    }
}

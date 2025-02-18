//
//  MoppLibCryptoActions.swift
//  MoppLib
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

import CryptoLib

public class MoppLibCryptoActions {

    /**
     * Decrypt CDOC container and get data files.
     *
     * @param fullPath      Full path of encrypted file.
     * @param pin1          PIN1 code.
     * @param success       Block to be called on successful completion of action. Includes decrypted data as NSMutableDictionary.
     * @param failure       Block to be called when action fails. Includes error.
     */
    static public func decryptData(fullPath: String, pin1: String) async throws -> [String: Data] {
        try await withUnsafeThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                do {
                    let result = try Decrypt.decryptFile(fullPath, withPin: pin1, with: SmartToken())
                    DispatchQueue.main.async { continuation.resume(returning: result) }
                } catch {
                    DispatchQueue.main.async { continuation.resume(throwing: error) }
                }
            }
        }
    }
}

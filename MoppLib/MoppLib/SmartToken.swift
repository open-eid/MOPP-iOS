//
//  SmartToken.swift
//  CryptoLib
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

class SmartToken: AbstractSmartToken {
    func getCertificate() throws -> Data {
        return try processCryptoOperation { handler in
            return try handler.readAuthenticationCertificate()
        }
    }

    func decrypt(_ data: Data, pin1: String) throws -> Data {
        return try processCryptoOperation { handler in
            return try handler.decryptData(data, withPin1: pin1)
        }
    }

    func derive(_ data: Data, pin1: String) throws -> Data {
        return try decrypt(data, pin1: pin1)
    }

    func authenticate(_ data: Data, pin1: String) throws -> Data {
        return try processCryptoOperation { handler in
            return try handler.authenticate(for: data, withPin1: pin1)
        }
    }

    private func processCryptoOperation(_ operation: (@escaping (CardCommands) throws -> Data)) throws -> Data {
        guard let handler = CardActionsManager.shared.cardCommandHandler else {
            throw MoppLibError.cardNotFoundError()
        }
        return try operation(handler)
    }
}

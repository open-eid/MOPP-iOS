//
//  MoppLibCardActions.swift
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

import Foundation

public class MoppLibCardActions: NSObject {

    /** Gets public personal data from ID card. */
    static public func cardPersonalData() async throws -> MoppLibPersonalData {
        try execute { try $0.readPublicData() }
    }

    /** Gets signing certificate data. */
    @objc static public func signingCertificate() throws -> Data {
        try execute { try $0.readSignatureCertificate() }
    }

    static public func signingCertificate() async throws -> Data {
        try execute { try $0.readSignatureCertificate() }
    }

    /** Gets authentication certificate data. */
    static public func authenticationCertificate() async throws -> Data {
        try execute { try $0.readAuthenticationCertificate() }
    }

    /** Gets PIN1 retry counter value. */
    static public func pin1RetryCount() async throws -> NSNumber {
        try execute { try $0.readCodeCounterRecord(.pin1) }
    }

    /** Gets PIN2 retry counter value. */
    @objc static public func pin2RetryCount() throws -> NSNumber {
        try execute { try $0.readCodeCounterRecord(.pin2) }
    }

    /** Gets PIN2 retry counter value. */
    static public func pin2RetryCount() async throws -> NSNumber {
        try execute { try $0.readCodeCounterRecord(.pin2) }
    }

    /** Gets PUK retry counter value. */
    static public func pukRetryCount() async throws -> NSNumber {
        try execute { try $0.readCodeCounterRecord(.puk) }
    }

    @objc static public func calculateSignatureFor(data: Data, pin2: String) throws -> Data {
        try execute { try $0.calculateSignature(for: data, withPin2: pin2) }
    }

    static private func execute<T>(action: @escaping (CardCommands) throws -> T) throws -> T {
        guard let handler = MoppLibCardReaderManager.shared.cardCommandHandler else {
            throw MoppLibError.cardNotFoundError()
        }
        return try action(handler)
    }
}

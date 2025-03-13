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

    /** Gets public personal data from ID card.
     *
     * @param success       Block to be called on successful completion of action. Includes card owner public personal data as MoppLibPersonalData.
     * @param failure       Block to be called when action fails. Includes Error.
     */
    static public func cardPersonalData(success: @escaping (MoppLibPersonalData) -> Void,
                                        failure: @escaping (Error) -> Void) {
        execute(failure: failure) { handler in
            success(try handler.readPublicData())
        }
    }

    /**
     * Gets signing certificate data.
     *
     * @param success       Block to be called on successful completion of action. Includes signing certificate data as MoppLibCertData
     * @param failure       Block to be called when action fails. Includes error.
     */
    @objc static public func signingCertificate(success: @escaping (Data) -> Void,
                                                failure: @escaping (Error) -> Void) {
        execute(failure: failure) { handler in
            success(try handler.readSignatureCertificate())
        }
    }

    /**
     * Gets authentication certificate data.
     *
     * @param success       Block to be called on successful completion of action. Includes authentication certificate data as MoppLibCertData
     * @param failure       Block to be called when action fails. Includes error.
     */
    static public func authenticationCertificate(success: @escaping (Data) -> Void,
                                                 failure: @escaping (Error) -> Void) {
        execute(failure: failure) { handler in
            success(try handler.readAuthenticationCertificate())
        }
    }

    /**
     * Gets PIN1 retry counter value.
     *
     * @param success       Block to be called on successful completion of action. Includes retry counter value as NSNumber
     * @param failure       Block to be called when action fails. Includes error.
     */
    static public func pin1RetryCount(success: @escaping (NSNumber) -> Void,
                                      failure: @escaping (Error) -> Void) {
        execute(failure: failure) { handler in
            success(try handler.readCodeCounterRecord(.pin1))
        }
    }

    /**
     * Gets PIN2 retry counter value.
     *
     * @param success       Block to be called on successful completion of action. Includes retry counter value as NSNumber
     * @param failure       Block to be called when action fails. Includes error.
     */
    @objc static public func pin2RetryCount(success: @escaping (NSNumber) -> Void,
                                            failure: @escaping (Error) -> Void) {
        execute(failure: failure) { handler in
            success(try handler.readCodeCounterRecord(.pin2))
        }
    }

    /**
     * Gets PUK retry counter value.
     *
     * @param success       Block to be called on successful completion of action. Includes retry counter value as NSNumber
     * @param failure       Block to be called when action fails. Includes error.
     */
    static public func pukRetryCount(success: @escaping (NSNumber) -> Void,
                                     failure: @escaping (Error) -> Void) {
        execute(failure: failure) { handler in
            success(try handler.readCodeCounterRecord(.puk))
        }
    }

    @objc static public func calculateSignatureFor(data: Data, pin2: String) throws -> Data {
        guard let handler = CardActionsManager.shared.cardCommandHandler else {
            throw MoppLibError.cardNotFoundError()
        }
        return try handler.calculateSignature(for: data, withPin2: pin2)
    }

    static private func execute(failure: @escaping (Error) -> Void, action: @escaping (CardCommands) throws -> Void) {
        guard let handler = CardActionsManager.shared.cardCommandHandler else {
            return failure(MoppLibError.cardNotFoundError())
        }
        do {
            try action(handler)
        } catch {
            failure(error)
        }
    }
}

//
//  CardCommands.swift
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

enum CodeType: UInt {
    case puk = 0
    case pin1 = 1
    case pin2 = 2
}

/**
 * A protocol defining commands for interacting with a smart card.
 */
protocol CardCommands {
    /**
     * Reads public data from the card.
     *
     * - Throws: An error if the operation fails.
     * - Returns: The personal data read from the card.
     */
    func readPublicData() throws -> MoppLibPersonalData

    /**
     * Reads the authentication certificate from the card.
     *
     * - Throws: An error if the operation fails.
     * - Returns: The authentication certificate as `Data`.
     */
    func readAuthenticationCertificate() throws -> Data

    /**
     * Reads the signature certificate from the card.
     *
     * - Throws: An error if the operation fails.
     * - Returns: The signature certificate as `Data`.
     */
    func readSignatureCertificate() throws -> Data

    /**
     * Reads the PIN or PUK code counter record.
     *
     * - Parameter type: The type of record to read.
     * - Throws: An error if the operation fails.
     * - Returns: The remaining attempts as an `NSNumber`.
     */
    func readCodeCounterRecord(_ type: CodeType) throws -> NSNumber

    /**
     * Changes the PIN or PUK code.
     *
     * - Parameters:
     *   - type: The type of code to change (e.g., `CodeTypePuk`, `CodeTypePin1`, `CodeTypePin2`).
     *   - code: The new PIN/PUK code.
     *   - verifyCode: The current PIN or PUK code for verification.
     * - Throws: An error if the operation fails.
     */
    func changeCode(_ type: CodeType, to code: String, verifyCode: String) throws

    /**
     * Verifies a PIN or PUK code.
     *
     * - Parameters:
     *   - type: The type of code to verify (e.g., `CodeTypePuk`, `CodeTypePin1`, `CodeTypePin2`).
     *   - code: The PIN/PUK code to verify.
     * - Throws: An error if the verification fails.
     */
    func verifyCode(_ type: CodeType, code: String) throws

    /**
     * Unblocks a PIN using the PUK code.
     *
     * - Parameters:
     *   - type: The type of code to unblock (`CodeTypePin1` or `CodeTypePin2`).
     *   - puk: The current PUK code for verification.
     *   - newCode: The new PIN code.
     * - Throws: An error if the operation fails.
     */
    func unblockCode(_ type: CodeType, puk: String, newCode: String) throws

    /**
     * Authenticates using a cryptographic challenge.
     *
     * - Parameters:
     *   - hash: The challenge hash to be signed.
     *   - pin1: PIN 1 for authentication.
     * - Throws: An error if the operation fails.
     * - Returns: The authentication response as `Data`.
     */
    func authenticate(for hash: Data, withPin1 pin1: String) throws -> Data

    /**
     * Calculates a digital signature for the given hash.
     *
     * - Parameters:
     *   - hash: The hash to be signed.
     *   - pin2: PIN 2 for verification.
     * - Throws: An error if the operation fails.
     * - Returns: The signature as `Data`.
     */
    func calculateSignature(for hash: Data, withPin2 pin2: String) throws -> Data

    /**
     * Decrypts data using PIN 1.
     *
     * - Parameters:
     *   - hash: The data to be decrypted.
     *   - pin1: PIN 1 for verification.
     * - Throws: An error if the operation fails.
     * - Returns: The decrypted data.
     */
    func decryptData(_ hash: Data, withPin1 pin1: String) throws -> Data
}

/**
 * Manages interactions with the smart card by delegating commands to `CardCommands` implementations.
 *
 * This class follows the singleton pattern to ensure a single instance is used throughout the app.
 */
class CardActionsManager: NSObject {

    /**
     * The shared singleton instance of `CardActionsManager`.
     */
    static let shared = CardActionsManager()

    /**
     * The command handler responsible for executing smart card operations.
     *
     * This should be assigned to an object conforming to the `CardCommands` protocol
     * before performing any smart card actions.
     */
    var cardCommandHandler: CardCommands?

    /**
     * Private initializer to enforce the singleton pattern.
     */
    private override init() {
        super.init()
    }
}

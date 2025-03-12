//
//  CardReaderWrapper.swift
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

typealias Bytes = [UInt8]

protocol CardReaderWrapper {
    /**
     * Sends a command to the card and retrieves the response.
     *
     * - Parameters:
     *   - commandHex: The command.
     *   - sw: A pointer to a `UInt16` variable that stores the status word (SW) from the card.
     * - Throws: An error if the transmission fails.
     * - Returns: The response data from the card.
     */
    func transmitCommand(_ apdu: Bytes) throws -> (Bytes,UInt16)

    /**
     * Sends a command to the card, retrieves the response, and verifies that the result is `0x9000` (success status).
     *
     * - Parameters:
     *   - commandHex: The command.
     *   - sw: A pointer to a `UInt16` variable that stores the status word (SW) from the card.
     * - Throws: An error if the transmission fails or if the response status word is not `0x9000`.
     * - Returns: The response data from the card.
     */
    func transmitCommandChecked(_ apdu: Bytes) throws -> Bytes

    /**
     * Powers on the card and retrieves the initial response.
     *
     * - Throws: An error if powering on the card fails.
     * - Returns: The response data from the card after power-on.
     */
    func powerOnCard() throws -> Bytes
}

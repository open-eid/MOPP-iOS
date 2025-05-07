//
//  CardReader.swift
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

protocol CardReader {
    /**
     * Sends an APDU (Application Protocol Data Unit) command to the smart card and retrieves the response.
     *
     * - Parameter apdu: The APDU command to be sent.
     * - Throws: An error if communication with the card fails.
     * - Returns: A tuple containing:
     *   - The response data from the card.
     *   - The status word (SW), which indicates the processing status of the command.
     */
    func transmit(_ apdu: Bytes) throws -> (Bytes, UInt16)

    /**
     * Powers on the smart card and retrieves its initial response (ATR - Answer to Reset).
     *
     * - Throws: An error if the card fails to power on.
     * - Returns: The ATR (Answer to Reset) response data from the card.
     */
    func powerOnCard() throws -> Bytes
}

extension CardReader {
    /**
     * Sends an APDU command to the card and retrieves the response, handling special status words (`0x6C00` and `0x6100`).
     *
     * - If the response status word is `0x6CXX`, the function resends the command with the correct length.
     * - If the response status word is `0x61XX`, the function retrieves additional response data.
     *
     * - Parameter apdu: The APDU command to be transmitted.
     * - Throws: An error if communication with the card fails.
     * - Returns: A tuple containing:
     *   - The full response data from the card.
     *   - The final status word (SW) from the card.
     */
    func transmitCommand(_ apdu: Bytes) throws -> (Bytes, UInt16) {
        var (response, sw) = try transmit(apdu)

        // Handle SW 6CXX (Wrong length, correct length provided in SW2)
        if (sw & 0xFF00) == 0x6C00 {
            var modifiedApdu = apdu
            modifiedApdu[apdu.count - 1] = UInt8(truncatingIfNeeded: sw)
            (response, sw) = try transmit(modifiedApdu)
        }

        // Handle SW 61XX (More data available, use GET RESPONSE command)
        while (sw & 0xFF00) == 0x6100 {
            let (additionalData, newSW) = try transmit([0x00, 0xC0, 0x00, 0x00, UInt8(truncatingIfNeeded: sw)])
            response.append(contentsOf: additionalData)
            sw = newSW
        }

        return (response, sw)
    }

    /**
     * Constructs and sends an APDU (Application Protocol Data Unit) command to the smart card.
     *
     * This method builds a command APDU according to ISO/IEC 7816-4 using the provided parameters
     * and transmits it using `transmitCommand`. It then checks the response status word (SW)
     * and throws an error unless it equals `0x9000`, indicating a successful operation.
     *
     * - Parameters:
     *   - cls: The class byte (CLA) of the command. Defaults to `0x00`.
     *   - ins: The instruction byte (INS) of the command.
     *   - p1: The first parameter byte (P1). Defaults to `0x00`.
     *   - p2: The second parameter byte (P2). Defaults to `0x00`.
     *   - data: Optional command data to include in the APDU body (`Lc + Data`).
     *   - le: Optional expected length of response data (`Le`). If provided, an `Le` byte is appended.
     *
     * - Throws: `MoppLibError.generalError()` if the card's status word is not `0x9000`,
     *           or any error thrown by `transmitCommand`.
     *
     * - Returns: The response data returned by the card (excluding the status word).
     */
    func sendAPDU(cls: UInt8 = 0x00, ins: UInt8, p1: UInt8 = 0x00, p2: UInt8 = 0x00,
                  data: (any RangeReplaceableCollection<UInt8>)? = nil, le: UInt8? = nil) throws -> Bytes {
        let apdu: Bytes = switch (data, le) {
        case (nil, nil): [cls, ins, p1, p2]
        case (nil, _): [cls, ins, p1, p2, le!]
        case (_, nil): [cls, ins, p1, p2, UInt8(data!.count)] + data!
        case (_, _): [cls, ins, p1, p2, UInt8(data!.count)] + data! + [le!]
        }
        let (result, sw) = try transmitCommand(apdu)
        guard sw == 0x9000 else {
            throw MoppLibError.Code.general
        }
        return result
    }

    func select(p1: UInt8 = 0x04, p2: UInt8 = 0x0C, file: Bytes) throws -> Bytes {
        return try sendAPDU(ins: 0xA4, p1: p1, p2: p2, data: file, le: p2 == 0x0C ? nil : 0x00)
    }
}

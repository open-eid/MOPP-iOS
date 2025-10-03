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

import CryptoTokenKit

public enum CodeType: UInt {
    case puk = 0
    case pin1 = 1
    case pin2 = 2
}

/**
 * A protocol defining commands for interacting with a smart card.
 */
public protocol CardCommands: AnyObject {
    var canChangePUK: Bool { get }

    /**
     * Reads public data from the card.
     *
     * - Throws: An error if the operation fails.
     * - Returns: The personal data read from the card.
     */
    func readPublicData() async throws -> MoppLibPersonalData

    /**
     * Reads the authentication certificate from the card.
     *
     * - Throws: An error if the operation fails.
     * - Returns: The authentication certificate as `Data`.
     */
    func readAuthenticationCertificate() async throws -> Data

    /**
     * Reads the signature certificate from the card.
     *
     * - Throws: An error if the operation fails.
     * - Returns: The signature certificate as `Data`.
     */
    func readSignatureCertificate() async throws -> Data

    /**
     * Reads the PIN or PUK code counter record.
     *
     * - Parameter type: The type of record to read.
     * - Throws: An error if the operation fails.
     * - Returns: The remaining attempts as an `NSNumber`.
     */
    func readCodeCounterRecord(_ type: CodeType) async throws -> UInt8

    /**
     * Changes the PIN or PUK code.
     *
     * - Parameters:
     *   - type: The type of code to change (e.g., `CodeTypePuk`, `CodeTypePin1`, `CodeTypePin2`).
     *   - code: The new PIN/PUK code.
     *   - verifyCode: The current PIN or PUK code for verification.
     * - Throws: An error if the operation fails.
     */
    func changeCode(_ type: CodeType, to code: String, verifyCode: String) async throws

    /**
     * Verifies a PIN or PUK code.
     *
     * - Parameters:
     *   - type: The type of code to verify (e.g., `CodeTypePuk`, `CodeTypePin1`, `CodeTypePin2`).
     *   - code: The PIN/PUK code to verify.
     * - Throws: An error if the verification fails.
     */
    func verifyCode(_ type: CodeType, code: String) async throws

    /**
     * Unblocks a PIN using the PUK code.
     *
     * - Parameters:
     *   - type: The type of code to unblock (`CodeTypePin1` or `CodeTypePin2`).
     *   - puk: The current PUK code for verification.
     *   - newCode: The new PIN code.
     * - Throws: An error if the operation fails.
     */
    func unblockCode(_ type: CodeType, puk: String, newCode: String) async throws

    /**
     * Authenticates using a cryptographic challenge.
     *
     * - Parameters:
     *   - hash: The challenge hash to be signed.
     *   - pin1: PIN 1 for authentication.
     * - Throws: An error if the operation fails.
     * - Returns: The authentication response as `Data`.
     */
    func authenticate(for hash: Data, withPin1 pin1: String) async throws -> Data

    /**
     * Calculates a digital signature for the given hash.
     *
     * - Parameters:
     *   - hash: The hash to be signed.
     *   - pin2: PIN 2 for verification.
     * - Throws: An error if the operation fails.
     * - Returns: The signature as `Data`.
     */
    func calculateSignature(for hash: Data, withPin2 pin2: String) async throws -> Data

    /**
     * Decrypts data using PIN 1.
     *
     * - Parameters:
     *   - hash: The data to be decrypted.
     *   - pin1: PIN 1 for verification.
     * - Throws: An error if the operation fails.
     * - Returns: The decrypted data.
     */
    func decryptData(_ hash: Data, withPin1 pin1: String) async throws -> Data
}

protocol CardCommandsInternal: CardCommands {
    /**
     * The smart card reader used to communicate with the card.
     *
     * Implementations may use this to send APDU commands and manage card sessions.
     */
    var reader: CardReader { get }

    var fillChar: UInt8 { get }
}

extension CardCommandsInternal {
    typealias TLV = TKBERTLVRecord

    func select(p1: UInt8 = 0x04, p2: UInt8 = 0x0C, file: Bytes) async throws -> Data {
        return try await reader.sendAPDU(ins: 0xA4, p1: p1, p2: p2, data: file, le: p2 == 0x0C ? nil : 0x00)
    }

    func readFile(p1: UInt8, file: Bytes) async throws -> Data {
        var size = 0xE5
        if let fci = TLV(from: Data(try await select(p1: p1, p2: 0x04, file: file))) {
            for record in TLV.sequenceOfRecords(from: fci.value) ?? [] where record.tag == 0x80 || record.tag == 0x81 {
                size = Int(record.value[0]) << 8 | Int(record.value[1])
            }
        }
        var data = Data()
        while data.count < size {
            data.append(contentsOf: try await reader.sendAPDU(
                ins: 0xB0, p1: UInt8(data.count >> 8), p2: UInt8(truncatingIfNeeded: data.count), le: UInt8(min(0xE5, size - data.count))))
        }
        return data
    }

    private func errorForPinActionResponse(execute: () async throws -> Void) async throws {
        do {
            try await execute()
        } catch let error as NSError {
            switch error.userInfo[MoppLibError.kMoppLibUserInfoSWError] as? NSNumber {
            case 0x9000: return
            case 0x6A80: // New pin is invalid
                throw MoppLibError.Code.pinMatchesOldCode
            case 0x63C0, 0x6983, 0x6984: // Authentication method blocked
                throw MoppLibError.Code.pinBlocked
            case let sw? where (sw.uint16Value & 0xFFF0) == 0x63C0: // For pin codes this means verification failed due to wrong pin
                throw MoppLibError.wrongPinError(withRetryCount: Int(sw.uint16Value & 0x000F)) // Last char in trailer holds retry count
            default:
                throw error
            }
        }
    }

    private func pinTemplate(_ pin: String?) -> Data {
        guard let pin else { return .init() }
        var data = pin.data(using: .utf8)!
        data.append(Data(repeating: fillChar, count: 12 - data.count))
        return data
    }

    func changeCode(_ pinRef: UInt8, to code: String, verifyCode: String) async throws {
        try await errorForPinActionResponse {
            _ = try await reader.sendAPDU(ins: 0x24, p2: pinRef, data: pinTemplate(verifyCode) + pinTemplate(code))
        }
    }

    func unblockCode(_ pinRef: UInt8, puk: String?, newCode: String) async throws {
        try await errorForPinActionResponse {
            _ = try await reader.sendAPDU(ins: 0x2C, p1: puk == nil ? 0x02 : 0x00, p2: pinRef, data: pinTemplate(puk) + pinTemplate(newCode))
        }
    }

    func verifyCode(_ pinRef: UInt8, code: String) async throws {
        try await errorForPinActionResponse {
            _ = try await reader.sendAPDU(ins: 0x20, p2: pinRef, data: pinTemplate(code))
        }
    }

    func setSecEnv(mode: UInt8, algo: Bytes? = nil, keyRef: UInt8) async throws {
        let algo: Data = algo != nil ? TLV(tag: 0x80, value: Data(algo!)).data : Data()
        _ = try await reader.sendAPDU(ins: 0x22, p1: 0x41, p2: mode,
                                data: algo + TLV(tag: 0x84, value: Data([keyRef])).data)
    }
}

extension Bytes {
    init(hex: String) {
        self = hex.split(separator: " ").compactMap { UInt8($0, radix: 16) }
    }
}

//
//  Thales.swift
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

extension CodeType {
    fileprivate var pinRef: UInt8 {
        switch self {
        case .pin1: return 0x81
        case .pin2: return 0x82
        case .puk: return 0x83
        }
    }
}

class Thales: CardCommandsInternal {
    static private let ATR = Bytes(hex: "3B FF 96 00 00 80 31 FE 43 80 31 B8 53 65 49 44 64 B0 85 05 10 12 23 3F 1D")
    static private let kAID = Bytes(hex: "A0 00 00 00 63 50 4B 43 53 2D 31 35")
    static private let AUTH_KEY: UInt8 = 0x01
    static private let SIGN_KEY: UInt8 = 0x05

    let canChangePUK: Bool = false
    let reader: CardReader
    let fillChar: UInt8 = 0x00

    init?(reader: any CardReader, atr: Bytes) throws {
        guard atr == Thales.ATR else {
            return nil
        }
        self.reader = reader
        _ = try select(file: Thales.kAID)
    }

    // MARK: - Public Data

    func readPublicData() throws -> MoppLibPersonalData {
        _ = try select(p1: 0x08, file: [0xDF, 0xDD])
        var personalData = MoppLibPersonalData()
        for recordNr: UInt8 in 1...8 {
            let data = try readFile(p1: 0x02, file: [0x50, recordNr])
            let record = String(data: Data(data), encoding: .utf8) ?? "-"
            switch recordNr {
            case 1: personalData.surname = record
            case 2: personalData.givenNames = record
            case 3: personalData.sex = record
            case 4: personalData.nationality = !record.isEmpty ? record : "-"
            case 5:
                let components = record.split(separator: " ")
                if components.count > 1 {
                    personalData.birthDate = String(components[0])
                    personalData.birthPlace = String(components[1])
                } else {
                    personalData.birthDate = "-"
                    personalData.birthPlace = "-"
                }
            case 6: personalData.personalIdentificationCode = record
            case 7: personalData.documentNumber = record
            case 8: personalData.expiryDate = record.replacingOccurrences(of: " ", with: ".")
            default: break
            }
        }
        return personalData
    }

    func readAuthenticationCertificate() throws -> Data {
        return try readFile(p1: 0x08, file: [0xAD, 0xF1, 0x34, 0x11])
    }

    func readSignatureCertificate() throws -> Data {
        return try readFile(p1: 0x08, file: [0xAD, 0xF2, 0x34, 0x21])
    }

    // MARK: - PIN & PUK Management
    func readCodeCounterRecord(_ type: CodeType) throws -> UInt8 {
        let data = try reader.sendAPDU(ins: 0xCB, p1: 0x00, p2: 0xFF, data:
            [0xA0, 0x03, 0x83, 0x01, type.pinRef], le: 0)
        if let info = TLV(from: Data(data)), info.tag == 0xA0 {
            for record in TLV.sequenceOfRecords(from: info.value) ?? [] where record.tag == 0xdf21 {
                return record.value[0]
            }
        }
        return 0
    }

    func changeCode(_ type: CodeType, to code: String, verifyCode: String) throws {
        guard type != .puk else {
            throw MoppLibError.Code.general
        }
        try changeCode(type.pinRef, to: code, verifyCode: verifyCode)
    }

    func verifyCode(_ type: CodeType, code: String) throws {
        try verifyCode(type.pinRef, code: code)
    }

    func unblockCode(_ type: CodeType, puk: String, newCode: String) throws {
        guard type != .puk else {
            throw MoppLibError.Code.general
        }
        try unblockCode(type.pinRef, puk: puk, newCode: newCode)
    }

    // MARK: - Authentication & Signing

    private func sign(type: CodeType, pin: String, keyRef: UInt8, hash: Data) throws -> Data {
        try verifyCode(type, code: pin)
        try setSecEnv(mode: 0xB6, algo: [0x24 + UInt8(hash.count)], keyRef: keyRef)
        _ = try reader.sendAPDU(ins: 0x2A, p1: 0x90, p2: 0xA0, data: TLV(tag: 0x90, value: Data(hash)).data)
        return Data(try reader.sendAPDU(ins: 0x2A, p1: 0x9E, p2: 0x9A, le: 0x00))
    }

    func authenticate(for hash: Data, withPin1 pin1: String) throws -> Data {
        return try sign(type: .pin1, pin: pin1, keyRef: Thales.AUTH_KEY, hash: hash)
    }

    func calculateSignature(for hash: Data, withPin2 pin2: String) throws -> Data {
        return try sign(type: .pin2, pin: pin2, keyRef: Thales.SIGN_KEY, hash: hash)
    }

    func decryptData(_ hash: Data, withPin1 pin1: String) throws -> Data {
        try verifyCode(.pin1, code: pin1)
        try setSecEnv(mode: 0xB8, keyRef: Thales.AUTH_KEY)
        return Data(try reader.sendAPDU(ins: 0x2A, p1: 0x80, p2: 0x86, data: [0x00] + hash, le: 0x00))
    }
}

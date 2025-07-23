//
//  Idemia.swift
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

extension CodeType {
    fileprivate var aid: Bytes {
        switch self {
        case .pin1: return Idemia.kAID
        case .pin2: return Idemia.kAID_QSCD
        case .puk: return Idemia.kAID
        }
    }
    fileprivate var pinRef: UInt8 {
        switch self {
        case .pin1: return 0x01
        case .pin2: return 0x85
        case .puk: return 0x02
        }
    }
}

class Idemia: CardCommandsInternal {
    static private let ATR = Bytes(hex: "3B DB 96 00 80 B1 FE 45 1F 83 00 12 23 3F 53 65 49 44 0F 90 00 F1")
    static private let ATRv2 = Bytes(hex: "3B DC 96 00 80 B1 FE 45 1F 83 00 12 23 3F 54 65 49 44 32 0F 90 00 C3")
    static fileprivate let kAID = Bytes(hex: "A0 00 00 00 77 01 08 00 07 00 00 FE 00 00 01 00")
    static fileprivate let kAID_QSCD = Bytes(hex: "51 53 43 44 20 41 70 70 6C 69 63 61 74 69 6F 6E")
    static private let kAID_Oberthur = Bytes(hex: "E8 28 BD 08 0F F2 50 4F 54 20 41 57 50")
    static private let AUTH_KEY: UInt8 = 0x81
    static private let SIGN_KEY: UInt8 = 0x9F

    let canChangePUK: Bool = true
    let reader: CardReader
    let fillChar: UInt8 = 0xFF

    required init?(reader: CardReader, atr: Bytes) {
        guard atr == Idemia.ATR || atr == Idemia.ATRv2 else {
            return nil
        }
        self.reader = reader
    }

    // MARK: - Public Data

    func readPublicData() async throws -> MoppLibPersonalData {
        _ = try select(file: Idemia.kAID)
        _ = try select(p1: 0x01, file: [0x50, 0x00])
        var personalData = MoppLibPersonalData()
        for recordNr: UInt8 in 1...8 {
            let data = try readFile(p1: 0x02, file: [0x50, recordNr])
            let record = String(data: data, encoding: .utf8) ?? "-"
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

    func readAuthenticationCertificate() async throws -> Data {
        _ = try select(file: Idemia.kAID)
        return try readFile(p1: 0x09, file: [0xAD, 0xF1, 0x34, 0x01])
    }

    func readSignatureCertificate() async throws -> Data {
        _ = try select(file: Idemia.kAID)
        return try readFile(p1: 0x09, file: [0xAD, 0xF2, 0x34, 0x1F])
    }

    // MARK: - PIN & PUK Management

    func readCodeCounterRecord(_ type: CodeType) async throws -> UInt8 {
        _ = try select(file: type.aid)
        let ref = type.pinRef & ~0x80
        let data = try reader.sendAPDU(ins: 0xCB, p1: 0x3F, p2: 0xFF, data:
            [0x4D, 0x08, 0x70, 0x06, 0xBF, 0x81, ref, 0x02, 0xA0, 0x80], le: 0x00)
        if let info = TLV(from: Data(data)), info.tag == 0x70,
           let tag = TLV(from: info.value), tag.tag == 0xBF8100 | UInt32(ref),
           let a0 = TLV(from: tag.value), a0.tag == 0xA0 {
            for record in TLV.sequenceOfRecords(from: a0.value) ?? [] where record.tag == 0x9B {
                return record.value[0]
            }
        }
        return 0
    }

    func changeCode(_ type: CodeType, to code: String, verifyCode: String) throws {
        _ = try select(file: type.aid)
        try changeCode(type.pinRef, to: code, verifyCode: verifyCode)
    }

    func verifyCode(_ type: CodeType, code: String) throws {
        try verifyCode(type.pinRef, code: code)
    }

    func unblockCode(_ type: CodeType, puk: String, newCode: String) throws {
        guard type != .puk else {
            throw MoppLibError.Code.general
        }
        try verifyCode(.puk, code: puk)
        if type == .pin2 {
            _ = try select(file: type.aid)
        }
        try unblockCode(type.pinRef, puk: nil, newCode: newCode)
    }

    // MARK: - Authentication & Signing

    func authenticate(for hash: Data, withPin1 pin1: String) throws -> Data {
        _ = try select(file: Idemia.kAID_Oberthur)
        try verifyCode(.pin1, code: pin1)
        try setSecEnv(mode: 0xA4, algo: [0xFF, 0x20, 0x08, 0x00], keyRef: Idemia.AUTH_KEY)
        var paddedHash = Data(repeating: 0x00, count: max(48, hash.count) - hash.count)
        paddedHash.append(hash)
        return Data(try reader.sendAPDU(ins: 0x88, data: paddedHash, le: 0x00))
    }

    func calculateSignature(for hash: Data, withPin2 pin2: String) throws -> Data {
        _ = try select(file: Idemia.kAID_QSCD)
        try verifyCode(.pin2, code: pin2)
        try setSecEnv(mode: 0xB6, algo: [0xFF, 0x15, 0x08, 0x00], keyRef: Idemia.SIGN_KEY)
        var paddedHash = Data(repeating: 0x00, count: max(48, hash.count) - hash.count)
        paddedHash.append(hash)
        return Data(try reader.sendAPDU(ins: 0x2A, p1: 0x9E, p2: 0x9A, data: paddedHash, le: 0x00))
    }

    func decryptData(_ hash: Data, withPin1 pin1: String) throws -> Data {
        _ = try select(file: Idemia.kAID_Oberthur)
        try verifyCode(.pin1, code: pin1)
        try setSecEnv(mode: 0xB8, algo: [0xFF, 0x30, 0x04, 0x00], keyRef: Idemia.AUTH_KEY)
        return Data(try reader.sendAPDU(ins: 0x2A, p1: 0x80, p2: 0x86, data: [0x00] + hash, le: 0x00))
    }
}

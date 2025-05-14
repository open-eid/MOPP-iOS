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

import CryptoTokenKit

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

class Idemia: CardCommands {
    private typealias TLV = TKBERTLVRecord

    static fileprivate let kAID = Bytes(hex: "A0 00 00 00 77 01 08 00 07 00 00 FE 00 00 01 00")
    static fileprivate let kAID_QSCD = Bytes(hex: "51 53 43 44 20 41 70 70 6C 69 63 61 74 69 6F 6E")
    static private let kAID_Oberthur = Bytes(hex: "E8 28 BD 08 0F F2 50 4F 54 20 41 57 50")
    static private let kSelectPersonalFile = Bytes(hex: "50 00")
    static private let kSelectAuthCert = Bytes(hex: "AD F1 34 01")
    static private let kSelectSignCert = Bytes(hex: "AD F2 34 1F")
    static private let kSetSecEnvAuth = Bytes(hex: "80 04 FF 20 08 00 84 01 81")
    static private let kSetSecEnvSign = Bytes(hex: "80 04 FF 15 08 00 84 01 9F")
    static private let kSetSecEnvDerive = Bytes(hex: "80 04 FF 30 04 00 84 01 81")
    static private let ATR = Bytes(hex: "3B DB 96 00 80 B1 FE 45 1F 83 00 12 23 3F 53 65 49 44 0F 90 00 F1")
    static private let ATRv2 = Bytes(hex: "3B DC 96 00 80 B1 FE 45 1F 83 00 12 23 3F 54 65 49 44 32 0F 90 00 C3")

    private let reader: CardReader

    required init?(reader: CardReader, atr: Bytes) {
        guard atr == Idemia.ATR || atr == Idemia.ATRv2 else {
            return nil
        }
        self.reader = reader
    }

    private func readFile(p1: UInt8, file: Bytes) throws -> Data {
        var size = 0xE7
        if let fci = TLV(from: Data(try reader.select(p1: p1, p2: 0x04, file: file))) {
            for record in TLV.sequenceOfRecords(from: fci.value) ?? [] where record.tag == 0x80 {
                size = Int(record.value[0]) << 8 | Int(record.value[1])
            }
        }
        var data = Bytes()
        while data.count < size {
            data.append(contentsOf: try reader.sendAPDU(
                ins: 0xB0, p1: UInt8(data.count >> 8), p2: UInt8(truncatingIfNeeded: data.count), le: UInt8(min(0xE7, size - data.count))))
        }
        return Data(data)
    }

    // MARK: - Public Data

    func readPublicData() async throws -> MoppLibPersonalData {
        _ = try reader.select(file: Idemia.kAID)
        _ = try reader.select(p1: 0x01, file: Idemia.kSelectPersonalFile)
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
        _ = try reader.select(file: Idemia.kAID)
        return try readFile(p1: 0x09, file: Idemia.kSelectAuthCert)
    }

    func readSignatureCertificate() async throws -> Data {
        _ = try reader.select(file: Idemia.kAID)
        return try readFile(p1: 0x09, file: Idemia.kSelectSignCert)
    }

    // MARK: - PIN & PUK Management

    private func errorForPinActionResponse(cmd: Bytes) throws {
        switch try reader.transmitCommand(cmd) {
        case (_, 0x9000): return
        case (_, 0x6A80): // New pin is invalid
            throw MoppLibError.Code.pinMatchesOldCode
        case (_, 0x63C0), (_, 0x6983): // Authentication method blocked
            throw MoppLibError.Code.pinBlocked
        case (_, let sw) where (sw & 0xFFF0) == 0x63C0: // For pin codes this means verification failed due to wrong pin
            throw MoppLibError.wrongPinError(withRetryCount: Int(sw & 0x000F)) // Last char in trailer holds retry count
        default:
            throw MoppLibError.Code.general
        }
    }

    private func pinTemplate(_ pin: String) -> Data {
        var data = pin.data(using: .utf8)!
        data.append(Data(repeating: 0xFF, count: 12 - data.count))
        return data
    }

    func readCodeCounterRecord(_ type: CodeType) async throws -> UInt8 {
        _ = try reader.select(file: type.aid)
        let ref = type.pinRef & ~0x80
        let data = try reader.sendAPDU(ins: 0xCB, p1: 0x3F, p2: 0xFF, data:
            [0x4D, 0x08, 0x70, 0x06, 0xBF, 0x81, ref, 0x02, 0xA0, 0x80], le: 0x00)
        if let info = TLV(from: Data(data)), info.tag == 0x70,
           let tag = TLV(from: info.value), tag.tag == 0xBF8100 | TKTLVTag(ref),
           let a0 = TLV(from: tag.value), a0.tag == 0xA0 {
            for record in TLV.sequenceOfRecords(from: a0.value) ?? [] where record.tag == 0x9B {
                return record.value[0]
            }
        }
        return 0
    }

    func changeCode(_ type: CodeType, to code: String, verifyCode: String) throws {
        _ = try reader.select(file: type.aid)
        let verifyPin = pinTemplate(verifyCode)
        let newPin = pinTemplate(code)
        let changeCmd = [0x00, 0x24, 0x00, type.pinRef, UInt8(verifyPin.count + newPin.count)]
        try errorForPinActionResponse(cmd: changeCmd + verifyPin + newPin)
    }

    func verifyCode(_ type: CodeType, code: String) throws {
        let pin = pinTemplate(code)
        let verifyCmd = [0x00, 0x20, 0x00, type.pinRef, UInt8(pin.count)]
        try errorForPinActionResponse(cmd: verifyCmd + pin)
    }

    func unblockCode(_ type: CodeType, puk: String, newCode: String) throws {
        guard type != .puk else {
            throw MoppLibError.Code.general
        }
        _ = try reader.select(file: type.aid)
        try verifyCode(.puk, code: puk)
        let newPin = pinTemplate(newCode)
        let unblockCmd = [0x00, 0x2C, 0x02, type.pinRef, UInt8(newPin.count)]
        try errorForPinActionResponse(cmd: unblockCmd + newPin)
    }

    // MARK: - Authentication & Signing

    func authenticate(for hash: Data, withPin1 pin1: String) throws -> Data {
        _ = try reader.select(file: Idemia.kAID_Oberthur)
        try verifyCode(.pin1, code: pin1)
        _ = try reader.sendAPDU(ins: 0x22, p1: 0x41, p2: 0xA4, data: Idemia.kSetSecEnvAuth)
        var paddedHash = Data(repeating: 0x00, count: max(48, hash.count) - hash.count)
        paddedHash.append(hash)
        return Data(try reader.sendAPDU(ins: 0x88, data: paddedHash, le: 0x00))
    }

    func calculateSignature(for hash: Data, withPin2 pin2: String) throws -> Data {
        _ = try reader.select(file: Idemia.kAID_QSCD)
        try verifyCode(.pin2, code: pin2)
        _ = try reader.sendAPDU(ins: 0x22, p1: 0x41, p2: 0xB6, data: Idemia.kSetSecEnvSign)
        var paddedHash = Data(repeating: 0x00, count: max(48, hash.count) - hash.count)
        paddedHash.append(hash)
        return Data(try reader.sendAPDU(ins: 0x2A, p1: 0x9E, p2: 0x9A, data: paddedHash, le: 0x00))
    }

    func decryptData(_ hash: Data, withPin1 pin1: String) throws -> Data {
        _ = try reader.select(file: Idemia.kAID_Oberthur)
        try verifyCode(.pin1, code: pin1)
        _ = try reader.sendAPDU(ins: 0x22, p1: 0x41, p2: 0xB8, data: Idemia.kSetSecEnvDerive)
        return Data(try reader.sendAPDU(ins: 0x2A, p1: 0x80, p2: 0x86, data: [0x00] + hash, le: 0x00))
    }
}

private extension Bytes {
    init(hex: String) {
        self = hex.split(separator: " ").compactMap { UInt8($0, radix: 16) }
    }
}

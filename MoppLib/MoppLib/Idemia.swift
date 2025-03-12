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

class Idemia: CardCommands {
    static private let kAID = Bytes(hex: "00 A4 04 0C 10 A0 00 00 00 77 01 08 00 07 00 00 FE 00 00 01 00")!
    static private let kAID_QSCD = Bytes(hex: "00 A4 04 0C 10 51 53 43 44 20 41 70 70 6C 69 63 61 74 69 6F 6E")!
    static private let kAID_Oberthur = Bytes(hex: "00 A4 04 0C 0D E8 28 BD 08 0F F2 50 4F 54 20 41 57 50")!
    static private let kSelectPersonalFile = Bytes(hex: "00 A4 01 0C 02 50 00")!
    static private let kSelectAuthCert = Bytes(hex: "00 A4 09 04 04 AD F1 34 01 00")!
    static private let kSelectSignCert = Bytes(hex: "00 A4 09 04 04 AD F2 34 1F 00")!
    static private let kSetSecEnvAuth = Bytes(hex: "00 22 41 A4 09 80 04 FF 20 08 00 84 01 81")!
    static private let kSetSecEnvSign = Bytes(hex: "00 22 41 B6 09 80 04 FF 15 08 00 84 01 9F")!
    static private let kSetSecEnvDerive = Bytes(hex: "00 22 41 B8 09 80 04 FF 30 04 00 84 01 81")!
    static private let ATR = Bytes(hex: "3B DB 96 00 80 B1 FE 45 1F 83 00 12 23 3F 53 65 49 44 0F 90 00 F1")!

    private let reader: CardReaderWrapper

    required init?(cardReader: CardReaderWrapper, atrData: Bytes) {
        guard atrData == Idemia.ATR else {
            return nil
        }
        reader = cardReader
    }

    private func readFile(file: Bytes) throws -> Data {
        var size = 0xE7
        if let fci = TKBERTLVRecord(from: Data(try reader.transmitCommandChecked(file))) {
            for record in TKBERTLVRecord.sequenceOfRecords(from: fci.value) ?? [] where record.tag == 0x80 {
                size = Int(record.value[0]) << 8 | Int(record.value[1])
            }
        }
        var data = Bytes()
        while data.count < size {
            data.append(contentsOf: try reader.transmitCommandChecked(
                [0x00, 0xB0, UInt8(data.count >> 8), UInt8(truncatingIfNeeded: data.count), UInt8(min(0xE7, size - data.count))]))
        }
        return Data(data)
    }

    // MARK: - Public Data

    func readPublicData() throws -> MoppLibPersonalData {
        _ = try reader.transmitCommandChecked(Idemia.kAID)
        _ = try reader.transmitCommandChecked(Idemia.kSelectPersonalFile)
        let personalData = MoppLibPersonalData()
        for recordNr in 1..<10 {
            let data = try readFile(file: [0x00, 0xA4, 0x02, 0x04, 0x02, 0x50, UInt8(recordNr)])
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

    func readAuthenticationCertificate() throws -> Data {
        _ = try reader.transmitCommandChecked(Idemia.kAID)
        return try readFile(file: Idemia.kSelectAuthCert)
    }

    func readSignatureCertificate() throws -> Data {
        _ = try reader.transmitCommandChecked(Idemia.kAID)
        return try readFile(file: Idemia.kSelectSignCert)
    }

    // MARK: - PIN & PUK Management

    private func aidAndRef(_ type: CodeType) -> (Bytes,UInt8) {
        switch type {
        case .pin1: return (Idemia.kAID, 1)
        case .pin2: return (Idemia.kAID_QSCD, 0x85)
        case .puk: return (Idemia.kAID, 2)
        }
    }

    private func errorForPinActionResponse(cmd: Bytes) throws {
        switch try reader.transmitCommand(cmd) {
        case (_, 0x9000): return
        case (_, 0x6A80): // New pin is invalid
            throw MoppLibError.pinMatchesOldCodeError()
        case (_, 0x63C0), (_, 0x6983): // Authentication method blocked
            throw MoppLibError.pinBlockedError()
        case (_, let sw) where (sw & 0xFFF0) == 0x63C0: // For pin codes this means verification failed due to wrong pin
            throw MoppLibError.wrongPinError(withRetryCount: Int(sw & 0x000F)) // Last char in trailer holds retry count
        default:
            throw MoppLibError.generalError()
        }
    }

    private func pinTemplate(_ pin: String) -> Data {
        var data = pin.data(using: .utf8)!
        data.append(Data(repeating: 0xFF, count: 12 - data.count))
        return data
    }

    func readCodeCounterRecord(_ type: CodeType) throws -> NSNumber {
        let (aid, recordNr): (Bytes, UInt8)
        switch type {
        case .pin1: (aid, recordNr) = (Idemia.kAID, 1)
        case .pin2: (aid, recordNr) = (Idemia.kAID_QSCD, 5)
        case .puk: (aid, recordNr) = (Idemia.kAID, 2)
        }
        _ = try reader.transmitCommandChecked(aid)
        let data = try reader.transmitCommandChecked(
            [0x00, 0xCB, 0x3F, 0xFF, 0x0A, 0x4D, 0x08, 0x70, 0x06, 0xBF, 0x81, recordNr, 0x02, 0xA0, 0x80, 0x00])
        return NSNumber(value: data[13])
    }

    func changeCode(_ type: CodeType, to code: String, verifyCode: String) throws {
        let (aid, pinRef) = aidAndRef(type)
        _ = try reader.transmitCommandChecked(aid)
        let verifyPin = pinTemplate(verifyCode)
        let newPin = pinTemplate(code)
        let changeCmd = [0x00, 0x24, 0x00, pinRef, UInt8(verifyPin.count + newPin.count)]
        try errorForPinActionResponse(cmd: changeCmd + verifyPin + newPin)
    }

    func verifyCode(_ type: CodeType, code: String) throws {
        let (aid, pinRef) = aidAndRef(type)
        _ = try reader.transmitCommandChecked(aid)
        let pin = pinTemplate(code)
        let verifyCmd = [0x00, 0x20, 0x00, pinRef, UInt8(pin.count)]
        try errorForPinActionResponse(cmd: verifyCmd + pin)
    }

    func unblockCode(_ type: CodeType, puk: String, newCode: String) throws {
        guard type != .puk else {
            throw MoppLibError.generalError()
        }
        try verifyCode(.puk, code: puk)
        let (aid, pinRef) = aidAndRef(type)
        _ = try reader.transmitCommandChecked(aid)
        let newPin = pinTemplate(newCode)
        let unblockCmd = [0x00, 0x2C, 0x02, pinRef,  UInt8(newPin.count)]
        try errorForPinActionResponse(cmd: unblockCmd + newPin)
    }

    // MARK: - Authentication & Signing

    func authenticate(for hash: Data, withPin1 pin1: String) throws -> Data {
        try verifyCode(.pin1, code: pin1)
        _ = try self.reader.transmitCommandChecked(Idemia.kAID_Oberthur)
        _ = try self.reader.transmitCommandChecked(Idemia.kSetSecEnvAuth)
        var paddedHash = Data(repeating: 0x00, count: max(48, hash.count) - hash.count)
        paddedHash.append(hash)
        let authCmd = [0x00, 0x88, 0x00, 0x00, UInt8(paddedHash.count)] + paddedHash + [0x00]
        return Data(try self.reader.transmitCommandChecked(authCmd))
    }

    func calculateSignature(for hash: Data, withPin2 pin2: String) throws -> Data {
        try verifyCode(.pin2, code: pin2)
        _ = try self.reader.transmitCommandChecked(Idemia.kSetSecEnvSign)
        var paddedHash = Data(repeating: 0x00, count: max(48, hash.count) - hash.count)
        paddedHash.append(hash)
        let signCmd = [0x00, 0x2A, 0x9E, 0x9A, UInt8(paddedHash.count)] + paddedHash + [0x00]
        return Data(try self.reader.transmitCommandChecked(signCmd))
    }

    func decryptData(_ hash: Data, withPin1 pin1: String) throws -> Data {
        try verifyCode(.pin1, code: pin1)
        _ = try self.reader.transmitCommandChecked(Idemia.kAID_Oberthur)
        _ = try self.reader.transmitCommandChecked(Idemia.kSetSecEnvDerive)
        let deriveCmd = [0x00, 0x2A, 0x80, 0x86, UInt8(hash.count + 1), 0x00] + hash + [0x00]
        return Data(try self.reader.transmitCommandChecked(deriveCmd))
    }
}

private extension MutableDataProtocol {
    init?(hex: String) {
        let cleanedHex = hex.replacingOccurrences(of: " ", with: "")
        guard cleanedHex.count % 2 == 0 else { return nil }

        var data = Self()
        var index = cleanedHex.startIndex

        while index < cleanedHex.endIndex {
            let nextIndex = cleanedHex.index(index, offsetBy: 2)
            guard let byte = UInt8(cleanedHex[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }

        self = data
    }
}

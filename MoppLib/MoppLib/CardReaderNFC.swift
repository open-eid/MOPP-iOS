/*
 * MoppLib - CardReaderNFC.swift
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

import SwiftECC
import CoreNFC
import CommonCrypto
import CryptoTokenKit
import SwiftECC
import BigInt

func printLog(_ message: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    if true || MoppLibConfiguration.isDebugMode || MoppLibConfiguration.isLoggingEnabled {
        NSLog("\(Date().ISO8601Format()) \(message)\n" +
              "\tFile: \((file as NSString).lastPathComponent), function: \(function), line: \(line)")
    }
}

class CardReaderNFC: CardReader {

    enum PasswordType: UInt8 {
        case id_PasswordType_MRZ = 1 // 0.4.0.127.0.7.2.2.12.1
        case id_PasswordType_CAN = 2 // 0.4.0.127.0.7.2.2.12.2
        var data: String {
            return switch self {
            case .id_PasswordType_MRZ: "04007F000702020C01"
            case .id_PasswordType_CAN: "04007F000702020C02"
            }
        }
    }
    enum MappingType: String {
        case id_PACE_ECDH_GM_AES_CBC_CMAC_256 = "04007f00070202040204" // 0.4.0.127.0.7.2.2.4.2.4
        var data: Data { return Data(hex: rawValue)! }
    }
    enum ParameterId: UInt8 {
        case EC256r1 = 12
        case BP256r1 = 13
        case EC384r1 = 15
        case BP384r1 = 16
        case BP512r1 = 17
        case EC521r1 = 18
        var domain: Domain {
            return switch self {
            case .EC256r1: .instance(curve: .EC256r1)
            case .EC384r1: .instance(curve: .EC384r1)
            case .EC521r1: .instance(curve: .EC521r1)
            case .BP256r1: .instance(curve: .BP256r1)
            case .BP384r1: .instance(curve: .BP384r1)
            case .BP512r1: .instance(curve: .BP512r1)
            }
        }
    }
    typealias TLV = TKBERTLVRecord

    let tag: NFCISO7816Tag
    var ksEnc: Bytes
    var ksMac: Bytes
    var SSC: Bytes = AES.Zero

    init(_ tag: NFCISO7816Tag, CAN: String) async throws {
        self.tag = tag

        printLog("Select CardAccess")
        _ = try await tag.sendCommand(cls: 0x00, ins: 0xA4, p1: 0x02, p2: 0x0C, data: Data([0x01, 0x1C]))
        printLog("Read CardAccess")
        let data = try await tag.sendCommand(cls: 0x00, ins: 0xB0, p1: 0x00, p2: 0x00, le: 256)

        guard let (mappingType, parameterId) = TLV.sequenceOfRecords(from: data)?
            .flatMap({ cardAccess in TLV.sequenceOfRecords(from: cardAccess.value) ?? [] })
            .compactMap({ tlv in
                if let records = TLV.sequenceOfRecords(from: tlv.value),
                   records.count == 3,
                   let mapping = MappingType(rawValue: records[0].value.hex),
                   let parameterId = ParameterId(rawValue: records[2].value[0]) {
                    return (mapping, parameterId)
                }
                return nil
            })
            .first else {
            printLog("Unsupported mapping")
            throw MoppLibError.error(message: "Unsupported mapping")
        }
        let domain = parameterId.domain

        _ = try await tag.sendCommand(cls: 0x00, ins: 0x22, p1: 0xc1, p2: 0xa4, records: [
            TLV(tag: 0x80, value: mappingType.data),
            TLV(tag: 0x83, bytes: [PasswordType.id_PasswordType_CAN.rawValue]),
            TLV(tag: 0x84, bytes: [parameterId.rawValue]),
        ])

        // Step1 - General Authentication
        let nonceEnc = try await tag.sendPaceCommand(records: [], tagExpected: 0x80)
        printLog("Challenge \(nonceEnc.hex)")
        let nonce = try CardReaderNFC.decryptNonce(CAN: CAN, encryptedNonce: nonceEnc)
        printLog("Nonce \(nonce.hex)")

        // Step2
        let (terminalPubKey, terminalPrivKey) = domain.makeKeyPair()
        let mappingKey = try await tag.sendPaceCommand(records: [try TLV(tag: 0x81, publicKey: terminalPubKey)], tagExpected: 0x82)
        printLog("Mapping key \(mappingKey.hex)")
        let cardPubKey = try ECPublicKey(domain: domain, point: mappingKey)!

        // Mapping
        let nonceS = BInt(magnitude: nonce)
        let mappingBasePoint = ECPublicKey(privateKey: try ECPrivateKey(domain: domain, s: nonceS)) // S*G
        printLog("Card Key x: \(mappingBasePoint.w.x.asMagnitudeBytes().hex), y: \(mappingBasePoint.w.y.asMagnitudeBytes().hex)")
        let sharedSecretH = try domain.multiplyPoint(cardPubKey.w, terminalPrivKey.s)
        printLog("Shared Secret x: \(sharedSecretH.x.asMagnitudeBytes().hex), y: \(sharedSecretH.y.asMagnitudeBytes().hex)")
        let mappedPoint = try domain.addPoints(mappingBasePoint.w, sharedSecretH) // MAP G = (S*G) + H

        // Ephemeral data
        printLog("Mapped point x: \(mappedPoint.x.asMagnitudeBytes().hex), y: \(mappedPoint.y.asMagnitudeBytes().hex)")
        let mappedDomain = try Domain.instance(name: domain.name + " Mapped", p: domain.p, a: domain.a, b: domain.b, gx: mappedPoint.x, gy: mappedPoint.y, order: domain.order, cofactor: domain.cofactor)
        let (terminalEphemeralPubKey, terminalEphemeralPrivKey) = mappedDomain.makeKeyPair()
        let ephemeralKey = try await tag.sendPaceCommand(records: [try TLV(tag: 0x83, publicKey: terminalEphemeralPubKey)], tagExpected: 0x84)
        printLog("Card Ephermal key \(ephemeralKey.hex)")
        let ephemeralCardPubKey = try ECPublicKey(domain: mappedDomain, point: ephemeralKey)!

        // Derive shared secret and session keys
        let sharedSecret = try terminalEphemeralPrivKey.sharedSecret(pubKey: ephemeralCardPubKey)
        printLog("Shared secret \(sharedSecret.hex)")
        ksEnc = CardReaderNFC.KDF(key: sharedSecret, counter: 1)
        ksMac = CardReaderNFC.KDF(key: sharedSecret, counter: 2)
        printLog("KS.Enc \(ksEnc.hex)")
        printLog("KS.Mac \(ksMac.hex)")

        // Mutual authentication
        let macCalc = try AES.CMAC(key: ksMac)

        let macHeader = TLV(tag: 0x7f49, records: [
            TLV(tag: 0x06, value: mappingType.data),
            TLV(tag: 0x86, bytes: try ephemeralCardPubKey.x963Representation())
        ])
        let macValue = try await tag.sendPaceCommand(records: [TLV(tag: 0x85, bytes: (try macCalc.authenticate(bytes: macHeader.data)))], tagExpected: 0x86)
        printLog("Mac response \(macValue.hex)")

        // verify chip's MAC
        let macResult = TLV(tag: 0x7f49, records: [
            TLV(tag: 0x06, value: mappingType.data),
            TLV(tag: 0x86, bytes: try terminalEphemeralPubKey.x963Representation())
        ])
        if macValue != Data(try macCalc.authenticate(bytes: macResult.data)) {
            throw MoppLibError.error(message: "Mutual authentication failed")
        }
    }

    func transmit(_ apduData: Bytes) async throws -> (Bytes, UInt16) {
        printLog("Plain >: \(apduData.hex)")
        guard let apdu = NFCISO7816APDU(data: Data(apduData)) else { throw MoppLibError.error(message: "Invalid APDU") }
        _ = SSC.increment()
        let DO87: Data
        if let data = apdu.data, !data.isEmpty {
            let iv = try AES.CBC(key: ksEnc).encrypt(SSC)
            let enc_data = try AES.CBC(key: ksEnc, iv: iv).encrypt(data.addPadding())
            DO87 = TLV(tag: 0x87, bytes: [0x01] + enc_data).data
        } else {
            DO87 = Data()
        }
        let DO97: Data
        if apdu.expectedResponseLength > 0 {
            DO97 = TLV(tag: 0x97, bytes: [UInt8(apdu.expectedResponseLength == 256 ? 0 : apdu.expectedResponseLength)]).data
        } else {
            DO97 = Data()
        }
        let cmd_header: Bytes = [apdu.instructionClass | 0x0C, apdu.instructionCode, apdu.p1Parameter, apdu.p2Parameter]
        let M = cmd_header.addPadding() + DO87 + DO97
        let N = SSC + M
        let mac = try AES.CMAC(key: ksMac).authenticate(bytes: N.addPadding())
        let DO8E = TLV(tag: 0x8E, bytes: mac).data
        let send = DO87 + DO97 + DO8E
        let response = try await tag.sendCommand(cls: cmd_header[0], ins: cmd_header[1], p1: cmd_header[2], p2: cmd_header[3], data: send, le: 256)
        var tlvEnc: TKTLVRecord?
        var tlvRes: TKTLVRecord?
        var tlvMac: TKTLVRecord?
        for tlv in TLV.sequenceOfRecords(from: response) ?? [] {
            switch tlv.tag {
            case 0x87: tlvEnc = tlv
            case 0x99: tlvRes = tlv
            case 0x8E: tlvMac = tlv
            default: printLog("Unknown tag")
            }
        }
        guard tlvRes != nil else {
            throw MoppLibError.error(message: "Missing RES tag")
        }
        guard tlvMac != nil else {
            throw MoppLibError.error(message: "Missing MAC tag")
        }
        let K = SSC.increment() + (tlvEnc?.data ?? Data()) + tlvRes!.data
        if try Data(AES.CMAC(key: ksMac).authenticate(bytes: K.addPadding())) != tlvMac!.value {
            throw MoppLibError.error(message: "Invalid MAC value")
        }
        guard tlvEnc != nil else {
            printLog("Plain <: \(tlvRes!.value.hex)")
            return (.init(), UInt16(tlvRes!.value[0], tlvRes!.value[1]))
        }
        let iv = try AES.CBC(key: ksEnc).encrypt(SSC)
        let responseData = try (try AES.CBC(key: ksEnc, iv: iv).decrypt(tlvEnc!.value[1...])).removePadding()
        printLog("Plain <:  \(responseData.hex) \(tlvRes!.value.hex)")
        return (Bytes(responseData), UInt16(tlvRes!.value[0], tlvRes!.value[1]))
    }

    // MARK: - Utils

    static private func decryptNonce<T : AES.DataType>(CAN: String, encryptedNonce: T) throws -> Bytes {
        let decryptionKey = KDF(key: Bytes(CAN.utf8), counter: 3)
        let cipher = AES.CBC(key: decryptionKey)
        return try cipher.decrypt(encryptedNonce)
    }

    static private func KDF(key: Bytes, counter: UInt8) -> Bytes {
        var keydata = key + Bytes(repeating: 0x00, count: 4)
        keydata[keydata.count - 1] = counter
        return SHA256(data: keydata)
    }

    static private func SHA256(data: Bytes) -> Bytes {
        Bytes(unsafeUninitializedCapacity: Int(CC_SHA256_DIGEST_LENGTH)) { buffer, initializedCount in
            CC_SHA256(data, CC_LONG(data.count), buffer.baseAddress)
            initializedCount = Int(CC_SHA256_DIGEST_LENGTH)
        }
    }
}


// MARK: - Extensions

extension DataProtocol {
    var hex: String {
        map { String(format: "%02x", $0) }.joined()
    }

    func chunked(into size: Int) -> [SubSequence] {
        stride(from: 0, to: count, by: size).map {
            self[index(startIndex, offsetBy: $0) ..< index(startIndex, offsetBy: Swift.min($0 + size, count))]
        }
    }

    func removePadding() throws -> SubSequence {
        var i = endIndex
        while i != startIndex {
            formIndex(before: &i)
            if self[i] == 0x80 {
                return self[startIndex..<i]
            } else if self[i] != 0x00 {
                throw MoppLibError.error(message: "Failed to remove padding")
            }
        }
        throw MoppLibError.error(message: "Failed to remove padding")
    }
}

extension MutableDataProtocol {
    static func ^ <D: Collection>(lhs: Self, rhs: D) -> Self where D.Element == Self.Element {
        precondition(lhs.count == rhs.count, "XOR operands must have equal length")
        var result = lhs
        for i in 0..<result.count {
            result[result.index(result.startIndex, offsetBy: i)] ^= rhs[rhs.index(rhs.startIndex, offsetBy: i)]
        }
        return result
    }

    mutating func increment() -> Self {
        var i = endIndex
        while i != startIndex {
            formIndex(before: &i)
            self[i] += 1
            if self[i] != 0 {
                break
            }
        }
        return self
    }

    func leftShiftOneBit() -> Self {
        var shifted = Self(repeating: 0x00, count: count)
        let last = index(before: endIndex)
        var i = startIndex
        while i < last {
            shifted[i] = self[i] << 1
            let next = index(after: i)
            if (self[next] & 0x80) != 0 {
                shifted[i] += 0x01
            }
            i = next
        }
        shifted[last] = self[last] << 1
        return shifted
    }

    init?(hex: String) {
        guard hex.count.isMultiple(of: 2) else { return nil }
        let chars = hex.map { $0 }
        let bytes = stride(from: 0, to: chars.count, by: 2)
            .map { String(chars[$0]) + String(chars[$0 + 1]) }
            .compactMap { UInt8($0, radix: 16) }
        guard hex.count / bytes.count == 2 else { return nil }
        self.init(bytes)
    }

    func addPadding() -> Self {
        var padding = Self(repeating: 0x00, count: AES.BlockSize - count % AES.BlockSize)
        padding[padding.startIndex] = 0x80
        return self + padding
    }
}

extension UInt16 {
    init(_ p1: UInt8, _ p2: UInt8) {
        self = (UInt16(p1) << 8) | UInt16(p2)
    }
}

extension ECPublicKey {
    convenience init?(domain: Domain, point: Data) throws {
        guard let w = try? domain.decodePoint(Bytes(point)) else { return nil }
        try self.init(domain: domain, w: w)
    }

    func x963Representation() throws -> Bytes {
        return try domain.encodePoint(w)
    }
}

extension NFCISO7816Tag {
    func sendCommand(cls: UInt8, ins: UInt8, p1: UInt8, p2: UInt8, data: Data = Data(), le: Int = -1) async throws -> Data {
        printLog(String(format: ">: %02X%02X%02X%02X \(data.hex) %02X", cls, ins, p1, p2, le > 0 ? le : 0x00))
        let apdu = NFCISO7816APDU(instructionClass: cls, instructionCode: ins, p1Parameter: p1, p2Parameter: p2, data: data, expectedResponseLength: le)
        let result = try await sendCommand(apdu: apdu)
        printLog(String(format: "<: \(result.0.hex) %02X%02X", result.1, result.2))
        switch result {
        case (_, 0x63, 0x00):
            throw MoppLibError.Code.wrongCan
        case (let data, 0x61, let len):
            return data + (try await sendCommand(cls: 0x00, ins: 0xC0, p1: 0x00, p2: 0x00, le: Int(len)))
        case (_, 0x6C, let len):
            return try await sendCommand(cls: cls, ins: ins, p1: p1, p2: p2, data: data, le: Int(len))
        //case (let data, 0x90, 0x00):
        case (let data, _, _):
            return data
        //case (_, let sw1, let sw2):
        //    throw MoppLibError.error(message: String(format: "%02X%02X", sw1, sw2))
        }
    }

    func sendCommand(cls: UInt8, ins: UInt8, p1: UInt8, p2: UInt8, records: [TKTLVRecord], le: Int = -1) async throws -> Data {
        let data = records.reduce(Data()) { partialResult, record in
            partialResult + record.data
        }
        return try await sendCommand(cls: cls, ins: ins, p1: p1, p2: p2, data: data, le: le)
    }

    func sendPaceCommand(records: [TKTLVRecord], tagExpected: TKTLVTag) async throws -> Data {
        let request = TKBERTLVRecord(tag: 0x7c, records: records)
        let data = try await sendCommand(cls: tagExpected == 0x86 ? 0x00 : 0x10, ins: 0x86, p1: 0x00, p2: 0x00, data: request.data, le: 256)
        if let response = TKBERTLVRecord(from: data), response.tag == 0x7c,
           let result = TKBERTLVRecord(from: response.value), result.tag == tagExpected {
            return result.value
        }
        throw MoppLibError.error(message: "Invalid response")
    }
}

extension TKBERTLVRecord {
    convenience init<T : DataProtocol>(tag: TKTLVTag, bytes: T) {
        self.init(tag: tag, value: Data(bytes))
    }

    convenience init(tag: TKTLVTag, publicKey: ECPublicKey) throws {
        self.init(tag: tag, bytes: (try publicKey.x963Representation()))
    }
}

// MARK: - AES
class AES {
    typealias DataType = DataProtocol & ContiguousBytes
    static let BlockSize: Int = kCCBlockSizeAES128
    static let Zero = Bytes(repeating: 0x00, count: BlockSize)

    class CBC {
        private let key: any DataType
        private let iv: any DataType

        init<K : DataType, I : DataType>(key: K, iv: I = Zero) {
            self.key = key
            self.iv = iv
        }

        func encrypt<T : DataType>(_ data: T) throws -> Bytes {
            return try crypt(data: data, operation: kCCEncrypt)
        }

        func decrypt<T : DataType>(_ data: T) throws -> Bytes {
            return try crypt(data: data, operation: kCCDecrypt)
        }

        private func crypt<T : DataType>(data: T, operation: Int) throws -> Bytes {
            try Bytes(unsafeUninitializedCapacity: data.count + BlockSize) { buffer, initializedCount in
                let status = data.withUnsafeBytes { dataBytes in
                    iv.withUnsafeBytes { ivBytes in
                        key.withUnsafeBytes { keyBytes in
                            CCCrypt(
                                CCOperation(operation),
                                CCAlgorithm(kCCAlgorithmAES),
                                CCOptions(0),
                                keyBytes.baseAddress, key.count,
                                ivBytes.baseAddress,
                                dataBytes.baseAddress, data.count,
                                buffer.baseAddress, buffer.count,
                                &initializedCount
                            )
                        }
                    }
                }
                guard status == kCCSuccess else {
                    throw MoppLibError.error(message: "AES.CBC.Error")
                }
            }
        }
    }

    class CMAC {
        static let Rb: Bytes = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x87]
        let cipher: AES.CBC
        let K1: Bytes
        let K2: Bytes

        init<T : DataType>(key: T) throws {
            cipher = AES.CBC(key: key)
            let L = try cipher.encrypt(Zero)
            K1 = (L[0] & 0x80) == 0 ? L.leftShiftOneBit() : L.leftShiftOneBit() ^ CMAC.Rb
            K2 = (K1[0] & 0x80) == 0 ? K1.leftShiftOneBit() : K1.leftShiftOneBit() ^ CMAC.Rb
        }

        func authenticate<T: DataType>(bytes: T, count: Int = 8) throws -> Bytes.SubSequence where T.Index == Int {
            var blocks = bytes.chunked(into: BlockSize)
            let M_last: Bytes
            if let last = blocks.popLast() {
                if bytes.count % BlockSize == 0 {
                    M_last = Bytes(last) ^ K1
                } else {
                    M_last = Bytes(last).addPadding() ^ K2
                }
            } else {
                M_last = Bytes().addPadding() ^ K1
            }

            var x = Bytes(repeating: 0x00, count: BlockSize)
            for M_i in blocks {
                let y = x ^ M_i
                x = try cipher.encrypt(y)
            }
            let y = x ^ M_last
            let T = try cipher.encrypt(y)
            return T[0..<count]
        }
    }
}

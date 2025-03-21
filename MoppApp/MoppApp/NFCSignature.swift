/*
 * MoppApp - NFCSignature.swift
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
import CoreNFC
import CommonCrypto
import CryptoTokenKit
import SwiftECC
import BigInt
import SkSigningLib

enum NFCError: Error {
    case error(msg: String)
    case pinError(attemptsLeft: UInt8)
}

class NFCSignature : NSObject, NFCTagReaderSessionDelegate {

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

    static let shared: NFCSignature = NFCSignature()
    private static let dateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyMMddHHmmssZ"
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df
    }()
    var session: NFCTagReaderSession?
    var CAN: String?
    var PIN: String?
    var containerPath: String?
    var roleInfo: MoppLibRoleAddressData?
    var ksEnc: Bytes?
    var ksMac: Bytes?
    var SSC: Bytes?
    var invalidateWithError: Bool = false

    func createNFCSignature(can: String, pin: String, containerPath: String, hashType: String, roleData: MoppLibRoleAddressData?) -> Void {
        guard NFCTagReaderSession.readingAvailable else {
            return CancelUtil.handleCancelledRequest(errorMessageDetails: L(.nfcDeviceNoSupport))
        }

        CAN = can
        PIN = pin
        roleInfo = roleData
        self.containerPath = containerPath
        invalidateWithError = false
        session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        session?.alertMessage = L(.nfcHoldNear)
        session?.begin()

        if UIAccessibility.isVoiceOverRunning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIAccessibility.post(notification: .announcement, argument: self.session?.alertMessage)
            }
        }
    }

    // MARK: - NFCTagReaderSessionDelegate

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        @Sendable func setSessionMessage(_ msg: String, invalidate: Bool = false) -> Void {
            invalidateWithError = invalidate

            if invalidate {
                session.invalidate(errorMessage: msg)
            } else {
                session.alertMessage = msg
            }
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: msg)
            }
        }
        if tags.count > 1 {
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            setSessionMessage(L(.nfcMultipleCards))
            return DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                session.restartPolling()
            }
        }

        guard case let .iso7816(tag) = tags.first else {
            return setSessionMessage(L(.nfcInvalidTag), invalidate: true)
        }

        Task {
            do {
                try await session.connect(to: tags.first!)
            } catch {
                return setSessionMessage(L(.nfcUnableConnect), invalidate: true)
            }
            do {
                setSessionMessage(L(.nfcAuth))
                guard let (ksEnc, ksMac) = try await mutualAuthenticate(tag: tag) else {
                    return setSessionMessage(L(.nfcAuthFailed), invalidate: true)
                }
                printLog("Mutual authentication successful")
                self.ksEnc = ksEnc
                self.ksMac = ksMac
                self.SSC = AES.Zero
                setSessionMessage(L(.nfcReadingCert))
                try await selectDF(tag: tag, file: [])
                try await selectDF(tag: tag, file: [0xAD, 0xF2])
                let cert = try await readEF(tag: tag, file: [0x34, 0x1F])

                guard let certData = TLV(from: cert), certData.tag == 0x30,
                      let certContent = TLV.sequenceOfRecords(from: certData.value), certContent.count == 3,
                      let certInfo = TLV.sequenceOfRecords(from: certContent[0].value), certInfo.count > 7,
                      let certValidity = TLV.sequenceOfRecords(from: certInfo[4].value), certValidity.count == 2,
                      let certExpire = String(data: certValidity[1].value, encoding: .ascii),
                      let expireDate = NFCSignature.dateFormatter.date(from: certExpire) else {
                    setSessionMessage(L(.nfcSignFailed), invalidate: true)
                    return ErrorUtil.generateError(signingError: L(.nfcCertParseFailed))
                }

                if expireDate < Date.now {
                    setSessionMessage(L(.nfcSignFailed), invalidate: true)
                    return ErrorUtil.generateError(signingError: L(.nfcCertExpired))
                }

                printLog("Cert reading done")
                guard let hash = MoppLibManager.prepareSignature(cert, containerPath: containerPath, roleData: roleInfo) else {
                    return setSessionMessage(L(.nfcSignFailed), invalidate: true)
                }
                roleInfo = nil
                setSessionMessage(L(.nfcSignDoc))
                var pin = Bytes(repeating: 0xFF, count: 12)
                pin.replaceSubrange(0..<PIN!.count, with: PIN!.utf8)
                _ = try await sendWrapped(tag: tag, cls: 0x00, ins: 0x22, p1: 0x41, p2: 0xb6, data: Bytes(hex: "80015484019f")!)
                _ = try await sendWrapped(tag: tag, cls: 0x00, ins: 0x20, p1: 0x00, p2: 0x85, data: pin)
                let signatureValue = try await sendWrapped(tag: tag, cls:0x00, ins: 0x2A, p1: 0x9E, p2: 0x9A, data: Bytes(hash), le: 256);
                printLog("\nRIA.NFC - Validating signature...\n")
                MoppLibManager.isSignatureValid(cert, signatureValue: signatureValue, success: {
                    printLog("\nRIA.NFC - Successfully validated signature!\n")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        NotificationCenter.default.post(
                            name: .signatureCreatedFinishedNotificationName,
                            object: nil,
                            userInfo: nil)
                    }
                    setSessionMessage(L(.nfcSignDone))
                    session.invalidate()
                }, failure: { (error: Error?) in
                    printLog("\nRIA.NFC - Error validating signature. Error: \(error?.localizedDescription ?? "Unable to display error")\n")
                    setSessionMessage(L(.nfcSignFailed), invalidate: true)
                    guard let err = error as NSError? else {
                        return ErrorUtil.generateError(signingError: .generalSignatureAddingError, details: MessageUtil.errorMessageWithDetails(details: "Unknown error"))
                    }
                    let details = MessageUtil.generateDetailedErrorMessage(error: err) ?? err.domain
                    switch err.code {
                    case 5, 6:
                        printLog("\nRIA.NFC - Certificate revoked. \(err.domain)")
                        ErrorUtil.generateError(signingError: .certificateRevoked, details: details)
                    case 7:
                        printLog("\nRIA.NFC - Invalid OCSP time slot. \(err.domain)")
                        ErrorUtil.generateError(signingError: .ocspInvalidTimeSlot, details: details)
                    case 18:
                        printLog("\nRIA.NFC - Too many requests. \(err.domain)")
                        ErrorUtil.generateError(signingError: .tooManyRequests(signingMethod: SigningType.nfc.rawValue), details: details)
                    case 20:
                        printLog("\nRIA.NFC - Failed to connect to host. \(err.domain)")
                        ErrorUtil.generateError(signingError: .invalidProxySettings)
                    default:
                        printLog("\nRIA.NFC - General signature adding error. \(err.domain)")
                        ErrorUtil.generateError(signingError: .empty, details: details)
                    }
                })
            } catch NFCError.pinError(let attemptsLeft) {
                printLog("\nRIA.NFC - PinError count \(attemptsLeft)")
                switch attemptsLeft {
                case 0: setSessionMessage(L(.pin2BlockedAlert), invalidate: true)
                case 1: setSessionMessage(L(.wrongPin2Single), invalidate: true)
                default: setSessionMessage(L(.nfcWrongPin2, [attemptsLeft]), invalidate: true)
                }
            } catch NFCError.error(let msg) {
                printLog("\nRIA.NFC - error \(msg)")
                setSessionMessage(L(.nfcSignFailed), invalidate: true)
            } catch {
                printLog("\nRIA.NFC - Error \(error.localizedDescription)")
                setSessionMessage(L(.nfcSignFailed), invalidate: true)
            }
        }
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if !invalidateWithError {
            if let readerError = error as? NFCReaderError,
               readerError.code == .readerSessionInvalidationErrorUserCanceled {
                CancelUtil.handleCancelledRequest(errorMessageDetails: "User cancelled NFC signing")
            } else {
                CancelUtil.handleCancelledRequest(errorMessageDetails: "Session Invalidated")
            }
        }
        self.session = nil
    }

    // MARK: - PACE
    func mutualAuthenticate(tag: NFCISO7816Tag) async throws -> (Bytes, Bytes)? {
        printLog("Select CardAccess")
        _ = try await tag.sendCommand(cls: 0x00, ins: 0xA4, p1: 0x02, p2: 0x0C, data: Data([0x01, 0x1C]))
        printLog("Read CardAccess")
        let data = try await tag.sendCommand(cls: 0x00, ins: 0xB0, p1: 0x00, p2: 0x00, le: 256)

        guard let (mappingType, domain) = TLV.sequenceOfRecords(from: data)?
            .flatMap({ cardAccess in TLV.sequenceOfRecords(from: cardAccess.value) ?? [] })
            .compactMap({ tlv in
                if let records = TLV.sequenceOfRecords(from: tlv.value),
                   records.count == 3,
                   let mapping = MappingType(rawValue: records[0].value.toHex),
                   let parameterId = ParameterId(rawValue: records[2].value[0]) {
                    return (mapping, parameterId.domain)
                }
                return nil
            })
            .first else {
            printLog("Unsupported mapping")
            return nil
        }

        _ = try await tag.sendCommand(cls: 0x00, ins: 0x22, p1: 0xc1, p2: 0xa4, records: [
            TLV(tag: 0x80, value: mappingType.data),
            TLV(tag: 0x83, value: Data([PasswordType.id_PasswordType_CAN.rawValue]))
        ])

        // Step1 - General Authentication
        let nonceEnc = try await tag.sendPaceCommand(records: [], tagExpected: 0x80)
        printLog("Challenge \(nonceEnc.toHex)")
        let nonce = try decryptNonce(encryptedNonce: nonceEnc)
        printLog("Nonce \(nonce.toHex)")

        // Step2
        let (terminalPubKey, terminalPrivKey) = domain.makeKeyPair()
        let mappingKey = try await tag.sendPaceCommand(records: [try TKBERTLVRecord(tag: 0x81, publicKey: terminalPubKey)], tagExpected: 0x82)
        printLog("Mapping key \(mappingKey.toHex)")
        let cardPubKey = try ECPublicKey(domain: domain, point: mappingKey)!

        // Mapping
        let nonceS = BInt(magnitude: nonce)
        let mappingBasePoint = ECPublicKey(privateKey: try ECPrivateKey(domain: domain, s: nonceS)) // S*G
        printLog("Card Key x: \(mappingBasePoint.w.x.asMagnitudeBytes().toHex), y: \(mappingBasePoint.w.y.asMagnitudeBytes().toHex)")
        let sharedSecretH = try domain.multiplyPoint(cardPubKey.w, terminalPrivKey.s)
        printLog("Shared Secret x: \(sharedSecretH.x.asMagnitudeBytes().toHex), y: \(sharedSecretH.y.asMagnitudeBytes().toHex)")
        let mappedPoint = try domain.addPoints(mappingBasePoint.w, sharedSecretH) // MAP G = (S*G) + H

        // Ephemeral data
        printLog("Mapped point x: \(mappedPoint.x.asMagnitudeBytes().toHex), y: \(mappedPoint.y.asMagnitudeBytes().toHex)")
        let mappedDomain = try Domain.instance(name: domain.name + " Mapped", p: domain.p, a: domain.a, b: domain.b, gx: mappedPoint.x, gy: mappedPoint.y, order: domain.order, cofactor: domain.cofactor)
        let (terminalEphemeralPubKey, terminalEphemeralPrivKey) = mappedDomain.makeKeyPair()
        let ephemeralKey = try await tag.sendPaceCommand(records: [try TLV(tag: 0x83, publicKey: terminalEphemeralPubKey)], tagExpected: 0x84)
        printLog("Card Ephermal key \(ephemeralKey.toHex)")
        let ephemeralCardPubKey = try ECPublicKey(domain: mappedDomain, point: ephemeralKey)!

        // Derive shared secret and session keys
        let sharedSecret = try terminalEphemeralPrivKey.sharedSecret(pubKey: ephemeralCardPubKey)
        printLog("Shared secret \(sharedSecret.toHex)")
        let ksEnc = KDF(key: sharedSecret, counter: 1)
        let ksMac = KDF(key: sharedSecret, counter: 2)
        printLog("KS.Enc \(ksEnc.toHex)")
        printLog("KS.Mac \(ksMac.toHex)")

        // Mutual authentication
        let macCalc = try AES.CMAC(key: ksMac)

        let macHeader = TLV(tag: 0x7f49, records: [
            TLV(tag: 0x06, value: mappingType.data),
            TLV(tag: 0x86, bytes: try ephemeralCardPubKey.x963Representation())
        ])
        let macValue = try await tag.sendPaceCommand(records: [TLV(tag: 0x85, bytes: (try macCalc.authenticate(bytes: macHeader.data)))], tagExpected: 0x86)
        printLog("Mac response \(macValue.toHex)")

        // verify chip's MAC and return session keys
        let macResult = TLV(tag: 0x7f49, records: [
            TLV(tag: 0x06, value: mappingType.data),
            TLV(tag: 0x86, bytes: try terminalEphemeralPubKey.x963Representation())
        ])
        if macValue == Data(try macCalc.authenticate(bytes: macResult.data)) {
            return (ksEnc, ksMac)
        }
        return nil
    }

    func sendWrapped(tag: NFCISO7816Tag, cls: UInt8, ins: UInt8, p1: UInt8, p2: UInt8, data: Bytes, le: Int = -1) async throws -> Data {
        guard SSC != nil else {
            return try await tag.sendCommand(cls: cls, ins: ins, p1: p1, p2: p2, data: Data(), le: le)
        }
        _ = SSC!.increment()
        let DO87: Data
        if !data.isEmpty {
            let iv = try AES.CBC(key: ksEnc!).encrypt(SSC!)
            let enc_data = try AES.CBC(key: ksEnc!, iv: iv).encrypt(data.addPadding())
            DO87 = TLV(tag: 0x87, bytes: [0x01] + enc_data).data
        } else {
            DO87 = Data()
        }
        let DO97: Data
        if le > 0 {
            DO97 = TLV(tag: 0x97, bytes: [UInt8(le == 256 ? 0 : le)]).data
        } else {
            DO97 = Data()
        }
        let cmd_header: Bytes = [cls | 0x0C, ins, p1, p2]
        let M = cmd_header.addPadding() + DO87 + DO97
        let N = SSC! + M
        let mac = try AES.CMAC(key: ksMac!).authenticate(bytes: N.addPadding())
        let DO8E = TLV(tag: 0x8E, bytes: mac).data
        let send = DO87 + DO97 + DO8E
        printLog(">: \(send.toHex)")
        let response = try await tag.sendCommand(cls: cmd_header[0], ins: ins, p1: p1, p2: p2, data: send, le: 256)
        printLog("<: \(response.toHex)")
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
            throw NFCError.error(msg: "Missing RES tag")
        }
        guard tlvMac != nil else {
            throw NFCError.error(msg: "Missing MAC tag")
        }
        let K = SSC!.increment() + (tlvEnc?.data ?? Data()) + tlvRes!.data
        if try Data(AES.CMAC(key: ksMac!).authenticate(bytes: K.addPadding())) != tlvMac!.value {
            throw NFCError.error(msg: "Invalid MAC value")
        }
        if tlvRes!.value != Data([0x90, 0x00]) {
            throw NFCError.error(msg: "\(tlvRes!.value.toHex)")
        }
        guard tlvEnc != nil else {
            return Data()
        }
        let iv = try AES.CBC(key: ksEnc!).encrypt(SSC!)
        let responseData = try AES.CBC(key: ksEnc!, iv: iv).decrypt(tlvEnc!.value[1...])
        return Data(try responseData.removePadding())
    }

    func selectDF(tag: NFCISO7816Tag, file: Bytes) async throws {
        _ = try await sendWrapped(tag: tag, cls: 0x00, ins: 0xA4, p1: file.isEmpty ? 0x00 : 0x01, p2: 0x0C, data: file, le: 256)
    }

    func selectEF(tag: NFCISO7816Tag, file: Bytes) async throws -> Int {
        let data = try await sendWrapped(tag: tag, cls: 0x00, ins: 0xA4, p1: 0x02, p2: 0x04, data: file, le: 256)
        guard let fci = TLV(from: data) else {
            return 0
        }
        for tlv in TLV.sequenceOfRecords(from: fci.value) ?? [] where tlv.tag == 0x80 {
            return Int(tlv.value[0]) << 8 | Int(tlv.value[1])
        }
        return 0
    }

    func readBinary(tag: NFCISO7816Tag, len: Int, pos: Int) async throws -> Data {
        return try await sendWrapped(tag: tag, cls: 0x00, ins: 0xB0, p1: UInt8(pos >> 8), p2: UInt8(truncatingIfNeeded: pos), data: [], le: len)
    }

    func readBinary(tag: NFCISO7816Tag, len: Int) async throws -> Data {
        var data = Data()
        for i in stride(from: 0, to: len, by: 0xE0) {
            data += try await readBinary(tag: tag, len: min(len - i, 0xE0), pos: i)
        }
        return data
    }

    func readEF(tag: NFCISO7816Tag, file: Bytes) async throws -> Data {
        let len = try await selectEF(tag: tag, file: file)
        return try await readBinary(tag: tag, len: len)
    }

    // MARK: - Utils

    private func decryptNonce(encryptedNonce: any AES.DataType) throws -> Bytes {
        let decryptionKey = KDF(key: Bytes(CAN!.utf8), counter: 3)
        let cipher = AES.CBC(key: decryptionKey)
        return try cipher.decrypt(encryptedNonce)
    }

    private func KDF(key: Bytes, counter: UInt8) -> Bytes {
        var keydata = key + Bytes(repeating: 0x00, count: 4)
        keydata[keydata.count - 1] = counter
        return SHA256(data: keydata)
    }

    private func SHA256(data: Bytes) -> Bytes {
        var hash = Bytes(repeating: 0x00, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { bufferPointer in
            CC_SHA256(bufferPointer.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash
    }
}


// MARK: - Extensions

extension DataProtocol where Self.Index == Int {
    var toHex: String {
        return map { String(format: "%02x", $0) }.joined()
    }

    func chunked(into size: Int) -> [Bytes] {
        return stride(from: 0, to: count, by: size).map {
            Bytes(self[$0 ..< Swift.min($0 + size, count)])
        }
    }

    func removePadding() throws -> SubSequence {
        for i in stride(from: count - 1, through: 0, by: -1) {
            if self[i] == 0x80 {
                return self[0..<i]
            } else if self[i] != 0x00 {
                throw NFCError.error(msg: "Failed to remove padding")
            }
        }
        throw NFCError.error(msg: "Failed to remove padding")
    }
}

extension MutableDataProtocol where Self.Index == Int {
    public static func ^ (x: Self, y: Self) -> Self {
        var result = x
        for i in 0..<result.count {
            result[i] ^= y[i]
        }
        return result
    }

    mutating func increment() -> Self {
        for i in (0..<count).reversed() {
            self[i] += 1
            if self[i] != 0 {
                break
            }
        }
        return self
    }

    func leftShiftOneBit() -> Self {
        var shifted = Self(repeating: 0x00, count: count)
        let last = count - 1
        for index in 0..<last {
            shifted[index] = self[index] << 1
            if (self[index + 1] & 0x80) != 0 {
                shifted[index] += 0x01
            }
        }
        shifted[last] = self[last] << 1
        return shifted
    }
}

extension MutableDataProtocol {
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

    mutating func resize(to size: Index) -> Self {
        self.removeSubrange(size..<endIndex)
        return self
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
        let apdu = NFCISO7816APDU(instructionClass: cls, instructionCode: ins, p1Parameter: p1, p2Parameter: p2, data: data, expectedResponseLength: le)
        switch try await sendCommand(apdu: apdu) {
        case (let data, 0x90, 0x00):
            return data
        case (let data, 0x61, let len):
            return data + (try await sendCommand(cls: 0x00, ins: 0xC0, p1: 0x00, p2: 0x00, data: Data(), le: Int(len)))
        case (_, 0x6C, let len):
            return try await sendCommand(cls: cls, ins: ins, p1: p1, p2: p2, data: data, le: Int(len))
        case (_, 0x63, let count) where count & 0xC0 > 0:
            throw NFCError.pinError(attemptsLeft: count & 0x0F)
        case (_, 0x69, 0x83):
            throw NFCError.pinError(attemptsLeft: 0)
        case (_, let sw1, let sw2):
            throw NFCError.error(msg: String(format: "%02X%02X", sw1, sw2))
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
        throw NFCError.error(msg: "Invalid response")
    }
}

extension TKBERTLVRecord {
    convenience init(tag: TKTLVTag, bytes: Bytes) {
        self.init(tag: tag, value: Data(bytes))
    }

    convenience init(tag: TKTLVTag, publicKey: ECPublicKey) throws {
        self.init(tag: tag, bytes: (try publicKey.x963Representation()))
    }
}

// MARK: - AES
class AES {
    public typealias DataType = DataProtocol & ContiguousBytes
    static let BlockSize: Int = kCCBlockSizeAES128
    static let Zero = Bytes(repeating: 0x00, count: BlockSize)

    public class CBC {
        private let key: any DataType
        private let iv: any DataType

        init(key: any DataType, iv: any DataType = Zero) {
            self.key = key
            self.iv = iv
        }

        func encrypt(_ data: any DataType) throws -> Bytes {
            return try crypt(data: data, operation: kCCEncrypt)
        }

        func decrypt(_ data: any DataType) throws -> Bytes {
            return try crypt(data: data, operation: kCCDecrypt)
        }

        private func crypt(data: any DataType, operation: Int) throws -> Bytes {
            var bytesWritten = 0
            var outputBuffer = Bytes(repeating: 0x00, count: data.count + BlockSize)
            let status = data.withUnsafeBytes { dataBytes in
                iv.withUnsafeBytes { ivBytes in
                    key.withUnsafeBytes { keyBytes in
                        CCCrypt(
                            CCOperation(operation),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(0),
                            keyBytes.baseAddress,
                            key.count,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress,
                            data.count,
                            &outputBuffer,
                            outputBuffer.count,
                            &bytesWritten
                        )
                    }
                }
            }
            if status != kCCSuccess {
                throw NFCError.error(msg: "AES.CBC.Error")
            }
            return outputBuffer.resize(to: bytesWritten)
        }
    }

    public class CMAC {
        static let Rb: Bytes = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x87]
        let cipher: AES.CBC
        let K1: Bytes
        let K2: Bytes

        public init(key: any DataType) throws {
            cipher = AES.CBC(key: key)
            let L = try cipher.encrypt(Zero)
            K1 = (L[0] & 0x80) == 0 ? L.leftShiftOneBit() : L.leftShiftOneBit() ^ CMAC.Rb
            K2 = (K1[0] & 0x80) == 0 ? K1.leftShiftOneBit() : K1.leftShiftOneBit() ^ CMAC.Rb
        }

        public func authenticate<T : DataType>(bytes: T, count: Int = 8) throws -> Bytes where T.Index == Int {
            let n = ceil(Double(bytes.count) / Double(BlockSize))
            let lastBlockComplete: Bool
            if n == 0 {
                lastBlockComplete = false
            } else {
                lastBlockComplete = bytes.count % BlockSize == 0
            }

            var blocks = bytes.chunked(into: BlockSize)
            var M_last = blocks.popLast() ?? Bytes()
            if lastBlockComplete {
                M_last = M_last ^ K1
            } else {
                M_last = M_last.addPadding() ^ K2
            }

            var x = Bytes(repeating: 0x00, count: BlockSize)
            var y: Bytes
            for M_i in blocks {
                y = x ^ M_i
                x = try cipher.encrypt(y)
            }
            y = M_last ^ x
            var T = try cipher.encrypt(y)
            return T.resize(to: count)
        }
    }
}

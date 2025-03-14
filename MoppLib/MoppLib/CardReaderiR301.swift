//
//  CardReaderIR301.swift

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

import iR301

class CardReaderiR301: CardReaderWrapper {
    private var contextHandle: SCARDCONTEXT
    private var cardHandle: SCARDHANDLE = 0
    private var pioSendPci = SCARD_IO_REQUEST(dwProtocol: UInt32(SCARD_PROTOCOL_UNDEFINED),
                                              cbPciLength: UInt32(MemoryLayout<SCARD_IO_REQUEST>.size))

    deinit {
        if cardHandle != 0 {
            SCardDisconnect(cardHandle, DWORD(SCARD_LEAVE_CARD))
        }
    }

    init?(contextHandle: SCARDCONTEXT) {
        guard contextHandle != 0 else {
            print("ID-CARD: Invalid context handle: \(contextHandle)")
            return nil
        }

        var modelNameLength: UInt32 = 100
        let modelName = String(unsafeUninitializedCapacity: Int(modelNameLength)) { buffer in
            guard FtGetAccessoryModelName(contextHandle, &modelNameLength, buffer.baseAddress) == 0 else {
                print("ID-CARD: Failed to identify reader")
                return 0
            }
            return Int(modelNameLength)
        }

        print("ID-CARD: Checking if card reader is supported: \(modelName)")
        guard modelName.hasPrefix("iR301") else {
            print("ID-CARD: Unsupported reader: \(modelName)")
            return nil
        }

        self.contextHandle = contextHandle
    }

    func transmitCommand(_ apdu: Bytes) throws -> (Bytes,UInt16) {
        print("ID-CARD: CardReaderiR301. transmitCommand.")
        var (response, sw) = try transmit(apdu)
        if (sw & 0xFF00) == 0x6C00 {
            var mutableApdu = apdu
            mutableApdu[apdu.count - 1] = UInt8(truncatingIfNeeded: sw)
            let (newResponse, newSW) = try transmit(mutableApdu)
            response = newResponse
            sw = newSW
        }

        while (sw & 0xFF00) == 0x6100 {
            let (data, newSW) = try transmit([0x00, 0xC0, 0x00, 0x00, UInt8(truncatingIfNeeded: sw)])
            sw = newSW
            response.append(contentsOf: data)
        }

        return (response,sw)
    }

    func transmitCommandChecked(_ apdu: Bytes) throws -> Bytes {
        let (result,sw) = try transmitCommand(apdu)
        guard sw == 0x9000 else {
            throw MoppLibError.generalError()
        }
        return result
    }

    func powerOnCard() throws -> Bytes {
        var dwReaders: DWORD = 128
        let mszReaders = try String(unsafeUninitializedCapacity: Int(dwReaders)) { buffer in
            let listReadersResult = SCardListReaders(contextHandle, nil, buffer.baseAddress, &dwReaders)
            guard listReadersResult == SCARD_S_SUCCESS else {
                print("SCardListReaders error \(listReadersResult)")
                throw MoppLibError.readerProcessFailedError()
            }
            return Int(dwReaders)
        }

        let connectResult = SCardConnect(contextHandle, mszReaders, DWORD(SCARD_SHARE_SHARED),
                                         DWORD(SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1), &cardHandle, &pioSendPci.dwProtocol)
        guard connectResult == SCARD_S_SUCCESS else {
            throw MoppLibError.readerProcessFailedError()
        }

        var atrSize: DWORD = 32
        var dwStatus: DWORD = 0
        let atr = try Bytes(unsafeUninitializedCapacity: Int(atrSize)) { buffer, initializedCount in
            guard SCardStatus(cardHandle, nil, nil, &dwStatus, nil, buffer.baseAddress, &atrSize) == SCARD_S_SUCCESS else {
                print("ID-CARD: Failed to get card status")
                throw MoppLibError.readerProcessFailedError()
            }
            initializedCount = Int(atrSize)
        }
        print("SCardStatus status: \(dwStatus) ATR: \(atr.hexString())")

        if dwStatus == SCARD_PRESENT {
            return atr
        } else {
            print("ID-CARD: Did not successfully power on card")
            throw MoppLibError.readerProcessFailedError()
        }
    }

    private func transmit(_ apdu: Bytes) throws -> (Bytes, UInt16) {
        print("ID-CARD: Transmitting APDU data \(apdu.hexString())")
        var responseSize: DWORD = 512
        var response = try Bytes(unsafeUninitializedCapacity: Int(responseSize)) { buffer, initializedCount in
            guard SCardTransmit(cardHandle, &pioSendPci, apdu, DWORD(apdu.count), nil, buffer.baseAddress, &responseSize) == SCARD_S_SUCCESS else {
                print("ID-CARD: Failed to send APDU data")
                throw MoppLibError.readerProcessFailedError()
            }
            initializedCount = Int(responseSize)
        }
        guard response.count >= 2 else {
            print("ID-CARD: Response size must be at least 2. Response size: \(response.count)")
            throw MoppLibError.readerProcessFailedError()
        }
        print("IR301 Response: \(response.hexString())")
        let sw = UInt16(response[response.count - 2]) << 8 | UInt16(response[response.count - 1])
        response.removeLast(2)
        return (response, sw)
    }
}

private extension DataProtocol {
    func hexString() -> String {
        return self.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}

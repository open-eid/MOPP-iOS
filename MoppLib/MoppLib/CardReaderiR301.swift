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

class CardReaderiR301: CardReader {
    let atr: Bytes
    private var cardHandle: SCARDHANDLE = 0
    private var pioSendPci = SCARD_IO_REQUEST(dwProtocol: UInt32(SCARD_PROTOCOL_UNDEFINED),
                                              cbPciLength: UInt32(MemoryLayout<SCARD_IO_REQUEST>.size))

    deinit {
        if cardHandle != 0 {
            SCardDisconnect(cardHandle, DWORD(SCARD_LEAVE_CARD))
        }
    }

    init?(contextHandle: SCARDCONTEXT) throws {
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

        var dwReaders: DWORD = 128
        let mszReaders = try String(unsafeUninitializedCapacity: Int(dwReaders)) { buffer in
            let listReadersResult = SCardListReaders(contextHandle, nil, buffer.baseAddress, &dwReaders)
            guard listReadersResult == SCARD_S_SUCCESS else {
                print("SCardListReaders error \(listReadersResult)")
                throw MoppLibError.Code.readerProcessFailed
            }
            return Int(dwReaders)
        }

        let connectResult = SCardConnect(contextHandle, mszReaders, DWORD(SCARD_SHARE_SHARED),
                                         DWORD(SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1), &cardHandle, &pioSendPci.dwProtocol)
        guard connectResult == SCARD_S_SUCCESS else {
            throw MoppLibError.Code.readerProcessFailed
        }

        var atrSize: DWORD = 32
        var dwStatus: DWORD = 0
        atr = try Bytes(unsafeUninitializedCapacity: Int(atrSize)) { [cardHandle] buffer, initializedCount in
            guard SCardStatus(cardHandle, nil, nil, &dwStatus, nil, buffer.baseAddress, &atrSize) == SCARD_S_SUCCESS else {
                print("ID-CARD: Failed to get card status")
                throw MoppLibError.Code.readerProcessFailed
            }
            initializedCount = Int(atrSize)
        }
        print("SCardStatus status: \(dwStatus) ATR: \(atr.hex))")

        guard dwStatus == SCARD_PRESENT else {
            print("ID-CARD: Did not successfully power on card")
            throw MoppLibError.Code.readerProcessFailed
        }
    }

    func transmit(_ apdu: Bytes) throws -> (Bytes, UInt16) {
        print("ID-CARD Transmitting: \(apdu.hex)")
        var responseSize: DWORD = 512
        var response = try Bytes(unsafeUninitializedCapacity: Int(responseSize)) { buffer, initializedCount in
            guard SCardTransmit(cardHandle, &pioSendPci, apdu, DWORD(apdu.count), nil, buffer.baseAddress, &responseSize) == SCARD_S_SUCCESS else {
                print("ID-CARD: Failed to send APDU data")
                throw MoppLibError.Code.readerProcessFailed
            }
            initializedCount = Int(responseSize)
        }
        guard response.count >= 2 else {
            print("ID-CARD: Response size must be at least 2. Response size: \(response.count)")
            throw MoppLibError.Code.readerProcessFailed
        }
        print("ID-CARD Response: \(response.hex)")
        let sw = UInt16(response[response.count - 2], response[response.count - 1])
        response.removeLast(2)
        return (response, sw)
    }
}

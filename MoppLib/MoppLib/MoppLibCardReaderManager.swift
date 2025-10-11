//
//  MoppLibCardReaderManager.swift
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

internal import iR301
import CoreNFC

public protocol MoppLibCardReaderManagerDelegate: AnyObject {
    func moppLibCardReaderStatusDidChange(_ status: MoppLibCardReaderStatus)
}

public enum MoppLibCardReaderStatus {
    case Initial
    case ReaderNotConnected
    case ReaderRestarted
    case ReaderConnected
    case CardConnected(CardCommands)
    case ReaderProcessFailed
}

public class MoppLibCardReaderManager {
    public static let shared = MoppLibCardReaderManager()

    public weak var delegate: MoppLibCardReaderManagerDelegate?
    fileprivate var handle: SCARDCONTEXT = 0
    private var handler = ReaderInterfaceHandler()
    fileprivate var status = MoppLibCardReaderStatus.Initial {
        didSet {
            let status = self.status
            DispatchQueue.main.async {
                self.delegate?.moppLibCardReaderStatusDidChange(status)
            }
        }
    }

    private init() {
    }

    static public func connectToCard(_ tag: NFCISO7816Tag, CAN: String) async throws -> CardCommands {
        let reader = try await CardReaderNFC(tag, CAN: CAN)
        guard let aid = Bytes(hex: tag.initialSelectedAID) else {
            throw MoppLibError.Code.cardNotFound
        }
        guard let cardCommands: CardCommands = Idemia(reader: reader, aid: aid) ?? Thales(reader: reader, aid: aid) else {
            throw MoppLibError.Code.cardNotFound
        }
        return cardCommands
    }

    public func startDiscoveringReaders() {
        guard handle == 0 else {
            printLog("ID-CARD: Reader discovery is already running")
            return
        }
        printLog("ID-CARD: Starting reader discovery")
        status = .Initial
        SCardEstablishContext(DWORD(SCARD_SCOPE_SYSTEM), nil, nil, &handle)
        printLog("ID-CARD: Started reader discovery: \(handle)")
    }

    public func stopDiscoveringReaders(with status: MoppLibCardReaderStatus = .Initial) {
        printLog("ID-CARD: Stopping reader discovery")
        self.status = status
        FtDidEnterBackground(1)
        SCardCancel(handle)
        SCardReleaseContext(handle)
        printLog("ID-CARD: Stopped reader discovery with status: \(handle)")
        handle = 0
    }
}

private class ReaderInterfaceHandler: NSObject, ReaderInterfaceDelegate {
    private let readerInterface = ReaderInterface()

    override init() {
        super.init()
        readerInterface.setDelegate(self)
    }

    func readerInterfaceDidChange(_ attached: Bool, bluetoothID: String?) {
        printLog("ID-CARD attached: \(attached)")
        MoppLibCardReaderManager.shared.status = attached ? .ReaderConnected : .ReaderNotConnected
    }

    func cardInterfaceDidDetach(_ attached: Bool) {
        printLog("ID-CARD: Card (interface) attached: \(attached)")
        do {
            guard attached, let reader = try CardReaderiR301(contextHandle: MoppLibCardReaderManager.shared.handle) else {
                return MoppLibCardReaderManager.shared.status = .ReaderConnected
            }
            if let handler: CardCommands = Idemia(reader: reader, atr: reader.atr) ?? (try? Thales(reader: reader, atr: reader.atr)) {
                MoppLibCardReaderManager.shared.status = .CardConnected(handler)
            }
        } catch {
            printLog("ID-CARD: Unable to power on card")
            MoppLibCardReaderManager.shared.status = .ReaderProcessFailed
        }
    }

    func didGetBattery(_ battery: Int) {
        // Implement if needed
    }

    func findPeripheralReader(_ readerName: String) {
        printLog("ID-CARD: Reader name: \(readerName)")
    }
}

func printLog(_ message: String, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    if MoppLibManager.isDebugMode || MoppLibManager.isLoggingEnabled {
        NSLog("\(Date().ISO8601Format()) \(message)\n" +
              "\tFile: \((file as NSString).lastPathComponent), function: \(function), line: \(line)")
    }
}

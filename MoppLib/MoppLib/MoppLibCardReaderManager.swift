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

import iR301

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
    private var status: MoppLibCardReaderStatus = .Initial

    private init() {
    }

    public func startDiscoveringReaders() {
        guard handle == 0 else {
            print("ID-CARD: Reader discovery is already running")
            return
        }
        print("ID-CARD: Starting reader discovery")
        updateStatus(status)
        SCardEstablishContext(DWORD(SCARD_SCOPE_SYSTEM), nil, nil, &handle)
        print("ID-CARD: Started reader discovery: \(handle)")
    }

    public func stopDiscoveringReaders(with status: MoppLibCardReaderStatus = .Initial) {
        print("ID-CARD: Stopping reader discovery")
        self.status = status
        FtDidEnterBackground(1)
        SCardCancel(handle)
        SCardReleaseContext(handle)
        print("ID-CARD: Stopped reader discovery with status: \(handle)")
        handle = 0
    }

    fileprivate func updateStatus(_ status: MoppLibCardReaderStatus) {
        self.status = status
        DispatchQueue.main.async {
            self.delegate?.moppLibCardReaderStatusDidChange(status)
        }
    }
}

private class ReaderInterfaceHandler: NSObject, ReaderInterfaceDelegate {
    private let readerInterface = ReaderInterface()

    override init() {
        super.init()
        readerInterface.setDelegate(self)
    }

    func readerInterfaceDidChange(_ attached: Bool, bluetoothID: String?) {
        print("ID-CARD attached: \(attached)")
        MoppLibCardReaderManager.shared.updateStatus(attached ? .ReaderConnected : .ReaderNotConnected)
    }

    func cardInterfaceDidDetach(_ attached: Bool) {
        print("ID-CARD: Card (interface) attached: \(attached)")
        guard attached, let reader = CardReaderiR301(contextHandle: MoppLibCardReaderManager.shared.handle) else {
            return MoppLibCardReaderManager.shared.updateStatus(.ReaderConnected)
        }
        do {
            let atr = try reader.powerOnCard()
            if let handler = Idemia(reader: reader, atr: atr) {
                MoppLibCardReaderManager.shared.updateStatus(.CardConnected(handler))
            }
        } catch {
            print("ID-CARD: Unable to power on card")
            MoppLibCardReaderManager.shared.updateStatus(.ReaderProcessFailed)
        }
    }

    func didGetBattery(_ battery: Int) {
        // Implement if needed
    }

    func findPeripheralReader(_ readerName: String) {
        print("ID-CARD: Reader name: \(readerName)")
    }
}

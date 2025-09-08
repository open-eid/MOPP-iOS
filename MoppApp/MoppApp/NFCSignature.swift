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

import ASN1Decoder
import CoreNFC
import SkSigningLib

class NFCSignature : NSObject, NFCTagReaderSessionDelegate {
    static let shared: NFCSignature = NFCSignature()
    var session: NFCTagReaderSession?
    var CAN: String!
    var PIN: String!
    var containerPath: String!
    var roleInfo: MoppLibRoleAddressData?
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
                guard let cardCommands = try? await MoppLibCardReaderManager.connectToCard(tag, CAN: CAN!) else {
                    return setSessionMessage(L(.nfcAuthFailed), invalidate: true)
                }
                printLog("Mutual authentication successful")
                setSessionMessage(L(.nfcReadingCert))
                let cert = try await cardCommands.readSignatureCertificate()
                guard let expireDate = try? X509Certificate(der: cert).notAfter else {
                    setSessionMessage(L(.nfcSignFailed), invalidate: true)
                    return ErrorUtil.generateError(signingError: L(.nfcCertParseFailed))
                }

                if expireDate < Date.now {
                    setSessionMessage(L(.nfcSignFailed), invalidate: true)
                    return ErrorUtil.generateError(signingError: L(.nfcCertExpired))
                }

                printLog("Cert reading done")
                let hash = try MoppLibContainerActions.prepareSignature(
                    cert,
                    containerPath: containerPath,
                    roleData: roleInfo,
                    sendDiagnostics: .NFC
                )
                roleInfo = nil
                setSessionMessage(L(.nfcSignDoc))
                let signatureValue = try await cardCommands.calculateSignature(for: hash, withPin2: PIN!)
                printLog("\nRIA.NFC - Validating signature...\n")
                try MoppLibContainerActions.isSignatureValid(signatureValue)
                printLog("\nRIA.NFC - Successfully validated signature!\n")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    NotificationCenter.default.post(
                        name: .signatureCreatedFinishedNotificationName,
                        object: nil,
                        userInfo: nil)
                }
                setSessionMessage(L(.nfcSignDone))
                session.invalidate()
            } catch let error as NSError where error == .wrongPin {
                let attemptsLeft = error.userInfo[MoppLibError.kMoppLibUserInfoRetryCount] as! Int
                printLog("\nRIA.NFC - PinError count \(attemptsLeft)")
                switch attemptsLeft {
                case 0: setSessionMessage(L(.pin2BlockedAlert), invalidate: true)
                case 1: setSessionMessage(L(.wrongPin2Single), invalidate: true)
                default: setSessionMessage(L(.nfcWrongPin2, [attemptsLeft]), invalidate: true)
                }

            } catch MoppLibError.Code.wrongCan {
                printLog("\nRIA.NFC - CAN error")
                setSessionMessage(L(.nfcSignFailedWrongCan), invalidate: true)
            } catch {
                printLog("\nRIA.NFC - Error \(error.localizedDescription)")
                ErrorUtil.generateError(signingError: error, signingType: SigningType.nfc)
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
}

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
    var invalidateWithError: Bool = false
    private var continuation: CheckedContinuation<NFCISO7816Tag, Error>?

    func createNFCSignature(can: String, pin: String, containerPath: String, hashType: String, roleData: MoppLibRoleAddressData?) -> Void {
        Task.detached {
            guard NFCTagReaderSession.readingAvailable else {
                return CancelUtil.handleCancelledRequest(errorMessageDetails: L(.nfcDeviceNoSupport))
            }

            guard let session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self) else {
                return CancelUtil.handleCancelledRequest(errorMessageDetails: L(.nfcDeviceNoSupport))
            }

            func setSessionMessage(_ msg: String, invalidate: Bool = false) -> Void {
                self.invalidateWithError = invalidate
                if invalidate {
                    session.invalidate(errorMessage: msg)
                } else {
                    session.alertMessage = msg
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if UIAccessibility.isVoiceOverRunning {
                        UIAccessibility.post(notification: .announcement, argument: msg)
                    }
                }
            }

            setSessionMessage(L(.nfcHoldNear))

            let tag: NFCISO7816Tag
            do {
                tag = try await withCheckedThrowingContinuation { continuation in
                    self.continuation = continuation
                    session.begin()
                }
                try await session.connect(to: .iso7816(tag))
            } catch {
                return setSessionMessage(L(.nfcUnableConnect), invalidate: true)
            }

            let cardCommands: CardCommands
            do {
                setSessionMessage(L(.nfcAuth))
                cardCommands = try await MoppLibCardReaderManager.connectToCard(tag, CAN: can)
                printLog("Mutual authentication successful")
            } catch MoppLibError.Code.wrongCan {
                return setSessionMessage(L(.nfcSignFailedWrongCan), invalidate: true)
            } catch {
                return setSessionMessage(L(.nfcAuthFailed), invalidate: true)
            }

            do {
                let (retryCount, pinActive) = try await cardCommands.readCodeCounterRecord(.pin2)
                if retryCount == 0 {
                    throw MoppLibError.Code.pinBlocked
                }
                if !pinActive {
                    throw MoppLibError.Code.pinLocked
                }

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
                    roleData: roleData,
                    sendDiagnostics: .NFC
                )
                setSessionMessage(L(.nfcSignDoc))
                let signatureValue = try await cardCommands.calculateSignature(for: hash, withPin2: pin)
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
            } catch {
                printLog("\nRIA.NFC - Error \(error.localizedDescription)")
                ErrorUtil.generateError(signingError: error, signingType: SigningType.nfc)
                setSessionMessage(L(.nfcSignFailed), invalidate: true)
            }
        }
    }

    // MARK: - NFCTagReaderSessionDelegate

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard tags.count == 1 else {
            session.alertMessage = L(.nfcMultipleCards)
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            return DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                session.restartPolling()
            }
        }

        if case let .iso7816(tag) = tags.first {
            continuation?.resume(returning: tag)
        } else {
            continuation?.resume(throwing: NFCReaderError(.readerTransceiveErrorTagNotConnected))
        }
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        guard !invalidateWithError else { return }
        if let readerError = error as? NFCReaderError,
           readerError.code == .readerSessionInvalidationErrorUserCanceled {
            CancelUtil.handleCancelledRequest(errorMessageDetails: "User cancelled NFC signing")
        } else {
            CancelUtil.handleCancelledRequest(errorMessageDetails: "Session Invalidated")
        }
    }
}

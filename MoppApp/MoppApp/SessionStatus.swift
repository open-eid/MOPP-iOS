//
//  SessionStatus.swift
//  MoppApp
//
/*
 * Copyright 2020 Riigi Infosüsteemide Amet
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
import SkSigningLib

class SessionStatus {
    
    static let shared: SessionStatus = SessionStatus()
    
    func getSessionStatus(baseUrl: String, process: PollingProcess, sessionId: String, timeoutMs: Int?, trustedCertificates: [String]?, completionHandler: @escaping (Result<SessionStatusResponse, MobileIDError>) -> Void ) {
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: TimeInterval(kDefaultTimeoutS), repeats: true) { timer in
                do {
                    _ = try RequestSession.shared.getSessionStatus(baseUrl: baseUrl, process: process, requestParameters: SessionStatusRequestParameters(sessionId: sessionId, timeoutMs: timeoutMs), trustedCertificates: trustedCertificates) { (sessionStatusResult: Result<SessionStatusResponse, MobileIDError>) in
                        switch sessionStatusResult {
                        case .success(let sessionStatus):
                            if self.isSessionStateComplete(sessionState: self.getSessionState(sessionStatus: sessionStatus)) {
                                NSLog("Received session status response: \(sessionStatus.result?.rawValue ?? "-")")
                                timer.invalidate()
                                return completionHandler(.success(sessionStatus))
                            }
                        case .failure(let sessionError):
                            NSLog("Getting Session Status error: \(sessionError.mobileIDErrorDescription ?? sessionError.rawValue)")
                            return completionHandler(.failure(sessionError))
                        }
                    }
                } catch let error {
                    NSLog("Error occurred while getting session status: \(error.localizedDescription)")
                    return completionHandler(.failure(.generalError))
                }
            }
        }
    }
    
    private func getSessionState(sessionStatus: SessionStatusResponse) -> SessionResponseState {
        let sessionState = sessionStatus.state
        switch sessionState {
        case .RUNNING:
            NSLog("Requesting session status... (currently: \(sessionState))")
        case .COMPLETE:
            NSLog("Requesting session status complete: (\(sessionState))!")
        }
        return sessionState
    }
    
    private func isSessionStateComplete(sessionState: SessionResponseState) -> Bool {
        return sessionState == SessionResponseState.COMPLETE
    }
}

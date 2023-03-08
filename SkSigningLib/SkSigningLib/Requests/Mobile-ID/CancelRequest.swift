//
//  CancelRequest.swift
//  SkSigningLib
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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

public protocol CancelRequest {
    func cancelRequest()
    func isRequestCancellationHandled(urlSession: URLSession?, urlSessionTask: URLSessionTask?, methodDescription: String) -> Bool
    func isRequestCancelled() -> Bool
    func resetCancelRequest()
}

public class RequestCancel: CancelRequest {
    
    public static let shared = RequestCancel()
    
    private var isCancelled = false
    
    public func cancelRequest() {
        isCancelled = true
    }
    
    public func isRequestCancellationHandled(urlSession: URLSession?, urlSessionTask: URLSessionTask?, methodDescription: String) -> Bool {
        if self.isCancelled {
            urlSession?.invalidateAndCancel()
            urlSessionTask?.cancel()
            Logging.errorLog(forMethod: methodDescription, httpResponse: nil, error: .cancelled, extraInfo: "Signing request cancelled")
            return true
        }
        
        return false
    }
    
    public func isRequestCancelled() -> Bool {
        return isCancelled
    }
    
    public func resetCancelRequest() {
        isCancelled = false
    }
}

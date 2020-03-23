//
//  RequestSession.swift
//  SkSigningLib
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

protocol SessionRequest {
    func getSession(baseUrl: String, requestParameters: SessionRequestParameters, completionHandler: @escaping (Result<SessionResponse, MobileIDError>) -> Void)
    func getSessionStatus(baseUrl: String, process: PollingProcess, requestParameters: SessionStatusRequestParameters, completionHandler: @escaping (Result<SessionStatusResponse, MobileIDError>) -> Void)
}

public class RequestSession: SessionRequest {
    
    public static let shared = RequestSession()
    
    public func getSession(baseUrl: String, requestParameters: SessionRequestParameters, completionHandler: @escaping (Result<SessionResponse, MobileIDError>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/signature") else {
            completionHandler(.failure(.invalidURL))
            return
        }
        
        let encodedRequestParameters: Data = EncoderDecoder().encode(data: requestParameters)
        
        var request = URLRequest(url: url)
        request.httpMethod = RequestMethod.POST.value
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedRequestParameters
        
        URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return completionHandler(.failure(.noResponseError))
            }
            
            if error != nil {
                completionHandler(.failure(.generalError))
                return
            }
            
            if let data: Data = data {
                EncoderDecoder().decode(data: data, completionHandler: { (response: SessionResponse) in
                    if (response.sessionID != nil) {
                        completionHandler(.success(response))
                    } else {
                        NSLog(response.error ?? "Unknown error received")
                        completionHandler(.failure(self.handleHTTPSessionResponseError(httpResponse: httpResponse)))
                    }
                })
            }
        }.resume()
    }
    
    public func getSessionStatus(baseUrl: String, process: PollingProcess, requestParameters: SessionStatusRequestParameters, completionHandler: @escaping (Result<SessionStatusResponse, MobileIDError>) -> Void) {
        
        guard let url = URL(string: "\(baseUrl)/signature/session/\(requestParameters.sessionId)?timeoutMs=\(requestParameters.timeoutMs ?? 1000)") else {
            return completionHandler(.failure(.invalidURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = RequestMethod.GET.value
        
        URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                return completionHandler(.failure(.noResponseError))
            }
            
            if error != nil {
                return completionHandler(.failure(.generalError))
            }
            
            if let data: Data = data {
                EncoderDecoder().decode(data: data, completionHandler: { (response: SessionStatusResponse) in
                    if (response.error == nil) {
                        return completionHandler(.success(response))
                    } else {
                        return completionHandler(.failure(self.handleHTTPSessionStatusResponseError(httpResponse: httpResponse)))
                    }
                })
            }
        }.resume()
    }
    
    private func handleHTTPSessionResponseError(httpResponse: HTTPURLResponse) -> MobileIDError {
        switch httpResponse.statusCode {
        case 400:
            return .parameterNameNull
        case 401:
            return .userAuthorizationFailed
        case 405:
            return .methodNotAllowed
        case 500:
            return .internalError
        default:
            return .generalError
        }
    }
    
    private func handleHTTPSessionStatusResponseError(httpResponse: HTTPURLResponse) -> MobileIDError {
        switch httpResponse.statusCode {
        case 400:
            return .sessionIdMissing
        case 401:
            return .userAuthorizationFailed
        case 404:
            return .sessionIdNotFound
        case 405:
            return .methodNotAllowed
        case 500:
            return .internalError
        default:
            return .generalError
        }
    }
    
}


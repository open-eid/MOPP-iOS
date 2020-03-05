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
    func getSession(baseUrl: String, requestParameters: SessionRequestParameters, completionHandler: @escaping (Result<SessionResponse, SessionResponseError>) -> Void)
    func getSessionStatus(baseUrl: String, process: PollingProcess, requestParameters: SessionStatusRequestParameters, completionHandler: @escaping (Result<SessionStatusResponse, SessionResponseError>) -> Void)
}

public class RequestSession: SessionRequest {
    
    public static let shared = RequestSession()
    
    public func getSession(baseUrl: String, requestParameters: SessionRequestParameters, completionHandler: @escaping (Result<SessionResponse, SessionResponseError>) -> Void) {
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
                        DispatchQueue.main.async {
                            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                                do {
                                    try self.getSessionStatus(baseUrl: baseUrl, process: PollingProcess.SIGNING, requestParameters: SessionStatusRequestParameters(sessionId: response.sessionID ?? "")) { (sessionStatusResult) in
                                        switch sessionStatusResult {
                                        case .success(let sessionStatus):
                                            if sessionStatus.state == SessionResponseState.COMPLETE {
                                                timer.invalidate()
                                                print("REQUEST COMPLETE")
                                                print(sessionStatus)
                                                completionHandler(.success(response))
                                            } else {
                                                print("REQUESTING...")
                                                print(sessionStatus)
                                            }
                                        case .failure(let sessionError):
                                            print(sessionError)
                                        }
                                    }
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    } else {
                        completionHandler(.failure(httpResponse.sessionErrorCode ?? .generalError))
                    }
                })
            }
        }.resume()
    }
    
    public func getSessionStatus(baseUrl: String, process: PollingProcess, requestParameters: SessionStatusRequestParameters, completionHandler: @escaping (Result<SessionStatusResponse, SessionResponseError>) -> Void) {
        
        guard let url = URL(string: "\(baseUrl)/signature/session/\(requestParameters.sessionId)?timeoutMs=\(requestParameters.timeoutMs ?? 1000)") else {
            completionHandler(.failure(.invalidURL))
            return
        }
        
        print(url)
        
        var request = URLRequest(url: url)
        request.httpMethod = RequestMethod.GET.value
        
        URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                return completionHandler(.failure(.noResponseError))
            }
            
            if error != nil {
                completionHandler(.failure(.generalError))
                return
            }
            
            if let data: Data = data {
                EncoderDecoder().decode(data: data, completionHandler: { (response: SessionStatusResponse) in
                    print(response)
                    completionHandler(.success(response))
                })
            }
        }.resume()
        
        
    }
    
}


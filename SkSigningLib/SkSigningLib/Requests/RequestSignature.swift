//
//  CertificateRequest.swift
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


protocol CertificateRequest {
    func getCertificate(baseUrl: String, requestParameters: CertificateRequestParameters, completionHandler: @escaping (Result<CertificateResponse, MobileIDError>) -> Void)
}

public class RequestSignature: CertificateRequest {
    
    public static let shared = RequestSignature()
    
    public func getCertificate(baseUrl: String, requestParameters: CertificateRequestParameters, completionHandler: @escaping (Result<CertificateResponse, MobileIDError>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/certificate") else {
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
            
            if !(200...299).contains(httpResponse.statusCode) {
                completionHandler(.failure(self.handleHTTPResponseError(httpResponse: httpResponse)))
            }
            
            if let data: Data = data {
                EncoderDecoder().decode(data: data, completionHandler: { (response: CertificateResponse) in
                    if self.isResponseSuccess(certificateResponse: response) {
                        completionHandler(.success(response))
                    } else {
                        completionHandler(.failure(self.handleCertificateError(certificateResponse: response)))
                    }
                })
            }
        }.resume()
    }
    
    private func handleCertificateError(certificateResponse: CertificateResponse) -> MobileIDError {
        guard let certificateResponseResult = certificateResponse.result else { return .generalError }
        switch certificateResponseResult {
        case ResponseResult.NOT_FOUND:
            return .notFound
        case ResponseResult.NOT_ACTIVE:
            return .notActive
        default:
            return .generalError
        }
    }
    
    private func handleHTTPResponseError(httpResponse: HTTPURLResponse) -> MobileIDError {
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
    
    private func isResponseSuccess(certificateResponse: CertificateResponse) -> Bool {
        if certificateResponse.result == ResponseResult.OK && certificateResponse.cert != nil {
            return true
        } else {
            return false
        }
    }
    
    private func handleResponseResult(responseResult: ResponseResult, completionHandler: @escaping (MobileIDError) -> Void) -> Void {
        switch responseResult {
        case ResponseResult.NOT_FOUND:
            completionHandler(.notFound)
        case ResponseResult.NOT_ACTIVE:
            completionHandler(.notActive)
        default:
            break
        }
    }
}

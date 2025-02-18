//
//  CertificateRequest.swift
//  SkSigningLib
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

import Foundation


protocol CertificateRequest {
    /**
    Gets certificate info for Mobile-ID

    - Parameters:
       - baseUrl: The base URL for Mobile-ID. Path "/certificate" will be added to the base URL
       - requestParameters: Parameters that are sent to the service. Uses CertificateRequestParameters struct
       - completionHandler: On request response, callbacks Result<CertificateResponse, SigningError>
    */
    func getCertificate(baseUrl: String, requestParameters: CertificateRequestParameters, trustedCertificates: [String]?, manualProxyConf: Proxy, completionHandler: @escaping (Result<CertificateResponse, SigningError>) -> Void)
}

/**
 Handles certificate info request for Mobile-ID
*/

public class RequestSignature: NSObject, URLSessionDelegate, CertificateRequest {
    
    public static let shared: RequestSignature = RequestSignature()
    private var trustedCerts: [String]?
    private weak var urlTask: URLSessionTask?
    
    public func getCertificate(baseUrl: String, requestParameters: CertificateRequestParameters, trustedCertificates: [String]?, manualProxyConf: Proxy, completionHandler: @escaping (Result<CertificateResponse, SigningError>) -> Void) {
        guard UUID(uuidString: requestParameters.relyingPartyUUID) != nil else { completionHandler(.failure(.midInvalidAccessRights)); return }
        guard let url = URL(string: "\(baseUrl)/certificate") else {
            Logging.errorLog(forMethod: "RIA.MobileID - Certificate", httpResponse: nil, error: .invalidURL, extraInfo: "Invalid URL \(baseUrl)/certificate")
            completionHandler(.failure(.invalidURL))
            return
        }
        
        trustedCerts = trustedCertificates
        
        let encodedRequestParameters: Data = EncoderDecoder().encode(data: requestParameters)
        
        var request = URLRequest(url: url)
        request.httpMethod = RequestMethod.POST.value
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedRequestParameters
        
        Logging.log(forMethod: "RIA.MobileID - getCertificate", info: "RIA.MobileID (Certificate): \(url) \n" +
            "Method: \(request.httpMethod ?? "Unable to get HTTP method") \n" +
            "Parameters: \n" +
            "\trelyingPartyName: \(requestParameters.relyingPartyName) \n" +
            "\trelyingPartyUUID: \(requestParameters.relyingPartyUUID) \n" +
            "\tphoneNumber: \(requestParameters.phoneNumber)\n" +
            "\tnationalIdentityNumber: \(requestParameters.nationalIdentityNumber)\n"
        )
        
        var urlSessionConfiguration: URLSessionConfiguration
        let urlSession: URLSession
        
        if !(trustedCerts?.isEmpty ?? true) {
            urlSessionConfiguration = URLSessionConfiguration.default
            ProxyUtil.configureURLSessionWithProxy(urlSessionConfiguration: &urlSessionConfiguration, manualProxyConf: manualProxyConf)
            ProxyUtil.setProxyAuthorizationHeader(request: &request, urlSessionConfiguration: urlSessionConfiguration, manualProxyConf: manualProxyConf)
            urlSession = URLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: nil)
        } else {
            urlSession = URLSession.shared
        }
        
        let certificateTask: URLSessionTask? = urlSession.dataTask(with: request as URLRequest) { data, response, error in
            let isRequestCancelled = CancelRequestUtil.isRequestCancellationHandled(urlSession: urlSession, urlSessionTask: self.urlTask, methodDescription: "RIA.MobileID - Certificate")
            
            if isRequestCancelled {
                completionHandler(.failure(.cancelled))
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let responseError = error as NSError?
                if responseError?.code == -999 || responseError?.code == -1200 {
                    Logging.errorLog(forMethod: "RIA.MobileID - Certificate", httpResponse: response as? HTTPURLResponse ?? nil, error: .invalidSSLCert, extraInfo: "Certificate pinning failed")
                    return completionHandler(.failure(.invalidSSLCert))
                } else if responseError?.code == 310 {
                    Logging.errorLog(forMethod: "RIA.MobileID - Certificate", httpResponse: response as? HTTPURLResponse ?? nil, error: .invalidProxySettings, extraInfo: "Unable to connect with current proxy settings")
                    return completionHandler(.failure(.invalidProxySettings))
                }
                Logging.errorLog(forMethod: "RIA.MobileID - Certificate", httpResponse: response as? HTTPURLResponse ?? nil, error: .noResponseError, extraInfo: "")
                return completionHandler(.failure(.noResponseError))
            }
            
            if error != nil {
                Logging.errorLog(forMethod: "RIA.MobileID - Certificate", httpResponse: response as? HTTPURLResponse ?? nil, error: .generalError, extraInfo: error?.localizedDescription ?? "Error getting response")
                completionHandler(.failure(.generalError))
                return
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                Logging.errorLog(forMethod: "RIA.MobileID - Certificate", httpResponse: httpResponse, error: self.handleHTTPResponseError(httpResponse: httpResponse), extraInfo: "")
                return completionHandler(.failure(self.handleHTTPResponseError(httpResponse: httpResponse)))
            }
            
            if let data: Data = data {
                EncoderDecoder().decode(data: data, completionHandler: { (response: CertificateResponse) in
                    Logging.log(forMethod: "RIA.MobileID - getCertificate", info: "Response: \n \(String(data: data, encoding: .utf8) ?? "Unable to get response info")")
                    if self.isResponseSuccess(certificateResponse: response) {
                        return completionHandler(.success(response))
                    } else {
                        Logging.errorLog(forMethod: "RIA.MobileID - Certificate", httpResponse: httpResponse, error: self.handleHTTPResponseError(httpResponse: httpResponse), extraInfo: response.error ?? "Unknown error received")
                        return completionHandler(.failure(self.handleCertificateError(certificateResponse: response)))
                    }
                })
            }
        }
        certificateTask?.resume()
        self.urlTask = certificateTask
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning().certificatePinning(trustedCertificates: trustedCerts ?? [""], challenge: challenge, completionHandler: completionHandler)
    }
    
    private func handleCertificateError(certificateResponse: CertificateResponse) -> SigningError {
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
    
    private func handleHTTPResponseError(httpResponse: HTTPURLResponse) -> SigningError {
        switch httpResponse.statusCode {
        case 400:
            return .parameterNameNull
        case 401:
            return .midInvalidAccessRights
        case 405:
            return .methodNotAllowed
        case 409:
            return .exceededUnsuccessfulRequests
        case 429:
            return .tooManyRequests(signingMethod: SigningType.mobileId.rawValue)
        case 500:
            return .internalError
        default:
            return .technicalError
        }
    }
    
    private func isResponseSuccess(certificateResponse: CertificateResponse) -> Bool {
        if certificateResponse.result == ResponseResult.OK && certificateResponse.cert != nil {
            return true
        } else {
            return false
        }
    }
    
    private func handleResponseResult(responseResult: ResponseResult, completionHandler: @escaping (SigningError) -> Void) -> Void {
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

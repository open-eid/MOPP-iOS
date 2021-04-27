/*
 * SkSigningLib - SIDRequest.swift
  * Copyright 2021 Riigi Infosüsteemi Amet
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

protocol SIDRequestProtocol {
    /**
    Gets certificate info for Smart-ID

    - Parameters:
       - baseUrl: The base URL for Smart-ID. Path "/certificate/pno/{country}/{nationalIdentityNumber}" will be added to the base URL
       - country:
       - nationalIdentityNumber:
       - requestParameters: Parameters that are sent to the service. Uses CertificateRequestParameters struct
       - completionHandler: On request success, callbacks Result<SIDSessionResponse, SigningError>
    */
    func getCertificate(baseUrl: String, country: String, nationalIdentityNumber: String, requestParameters: SIDCertificateRequestParameters, trustedCertificates: [String]?, completionHandler: @escaping (Result<SIDSessionResponse, SigningError>) -> Void)

    /**
    Gets signature info for Smart-ID.

    - Parameters:
       - baseUrl: The base URL for Smart-ID. Path "/signature/document/{documentNumber}" will be added to the base URL
       - documentNumber:
       - requestParameters: Parameters that are sent to the service.
       - completionHandler: On request success, callbacks Result<SIDSessionResponse, SigningError>
    */
    func getSignature(baseUrl: String, documentNumber: String, requestParameters: SIDSignatureRequestParameters, trustedCertificates: [String]?, completionHandler: @escaping (Result<SIDSessionResponse, SigningError>) -> Void)

    /**
    Gets session status info for Smart-ID.

    - Parameters:
       - baseUrl: The base URL for Smart-ID. Path "/session/{sessionId}?timeoutMs={timeoutMs}" will be added to the base URL. Values are taken from requestParameters
       - sessionId: SessionID parameter that is used in URL
       - timeoutMs: TimeoutMs parameter that is used in URL
       - completionHandler: On request success, callbacks Result<SIDSessionStatusResponse, SigningError>
    */
    func getSessionStatus(baseUrl: String, sessionId: String, timeoutMs: Int?, trustedCertificates: [String]?, completionHandler: @escaping (Result<SIDSessionStatusResponse, SigningError>) -> Void)
}

/**
 Handles session and session status requests for Mobile-ID
*/
public class SIDRequest: NSObject, URLSessionDelegate, SIDRequestProtocol {

    public static let shared = SIDRequest()
    private var trustedCerts: [String]?

    public func getCertificate(baseUrl: String, country: String, nationalIdentityNumber: String, requestParameters: SIDCertificateRequestParameters, trustedCertificates: [String]?, completionHandler: @escaping (Result<SIDSessionResponse, SigningError>) -> Void) {
        let url = "\(baseUrl)/certificatechoice/pno/\(country)/\(nationalIdentityNumber)"
        guard UUID(uuidString: requestParameters.relyingPartyUUID) != nil else { completionHandler(.failure(.sidInvalidAccessRights)); return }
        exec(method: "Certificate", url: url, data: EncoderDecoder().encode(data: requestParameters), trustedCertificates: trustedCertificates, completionHandler: completionHandler)
    }

    public func getSignature(baseUrl: String, documentNumber: String, requestParameters: SIDSignatureRequestParameters, trustedCertificates: [String]?, completionHandler: @escaping (Result<SIDSessionResponse, SigningError>) -> Void) {
        let url = "\(baseUrl)/signature/document/\(documentNumber)"
        exec(method: "Signature", url: url, data: EncoderDecoder().encode(data: requestParameters), trustedCertificates: trustedCertificates, completionHandler: completionHandler)
    }

    public func getSessionStatus(baseUrl: String, sessionId: String, timeoutMs: Int?, trustedCertificates: [String]?, completionHandler: @escaping (Result<SIDSessionStatusResponse, SigningError>) -> Void) {
        let url = "\(baseUrl)/session/\(sessionId)?timeoutMs=\(timeoutMs ?? Constants.defaultTimeoutMs)"
        exec(method: "Session", url: url, data: nil, trustedCertificates: trustedCertificates, completionHandler: completionHandler)
    }

    private func exec<D: Decodable>(method: String, url: String, data: Data?, trustedCertificates: [String]?, completionHandler: @escaping (Result<D, SigningError>) -> Void) {
        guard let _url = URL(string: url) else {
            ErrorLog.errorLog(forMethod: method, httpResponse: nil, error: .invalidURL, extraInfo: "Invalid URL \(url)")
            return completionHandler(.failure(.invalidURL))
        }
        var request = URLRequest(url: _url)
        request.httpMethod = data == nil ? RequestMethod.GET.value : RequestMethod.POST.value
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

#if DEBUG
        NSLog("RIA.SmartID (\(method): \(url)\n" +
            "Method: \(request.httpMethod ?? "Unable to get HTTP method")\n" +
            "Data: \n" + String(data: data ?? Data(), encoding: .utf8)!
        )
#endif

        trustedCerts = trustedCertificates
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        URLSession(configuration: config, delegate: trustedCertificates != nil ? self : nil, delegateQueue: nil)
            .dataTask(with: request) { data, response, error in
            switch error {
            case nil: break
            case let nsError as NSError where nsError.code == NSURLErrorCancelled || nsError.code == NSURLErrorSecureConnectionFailed:
                ErrorLog.errorLog(forMethod: method, httpResponse: nil, error: .invalidSSLCert, extraInfo: "Certificate pinning failed")
                return completionHandler(.failure(.invalidSSLCert))
            case let nsError as NSError where nsError.code == NSURLErrorNotConnectedToInternet:
                ErrorLog.errorLog(forMethod: method, httpResponse: nil, error: .noResponseError, extraInfo: "Error getting response. No Internet connection")
                return completionHandler(.failure(.noResponseError))
            default:
                ErrorLog.errorLog(forMethod: method, httpResponse: nil, error: .generalError, extraInfo: error!.localizedDescription)
                return completionHandler(.failure(.generalError))
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                ErrorLog.errorLog(forMethod: method, httpResponse: nil, error: .noResponseError, extraInfo: "Error getting response")
                return completionHandler(.failure(.noResponseError))
            }
            if !(200...299).contains(httpResponse.statusCode) {
                let statusCode: SigningError = {
                  switch httpResponse.statusCode {
                  case 400: return .forbidden
                  case 401, 403: return .sidInvalidAccessRights
                  case 404: return method == "Session" ? .sessionIdNotFound : .accountNotFound
                  case 409: return .exceededUnsuccessfulRequests
                  case 429: return .tooManyRequests
                  case 471: return .notQualified
                  case 480: return .oldApi
                  case 500: return .internalError
                  case 580: return .underMaintenance
                  default: return .generalError
                  }
                }()
                ErrorLog.errorLog(forMethod: method, httpResponse: httpResponse, error: statusCode, extraInfo: "")
                return completionHandler(.failure(statusCode))
            }
            if data == nil {
                ErrorLog.errorLog(forMethod: method, httpResponse: httpResponse, error: .generalError, extraInfo: "Error getting response")
                return completionHandler(.failure(.generalError))
            }
#if DEBUG
            NSLog("RIA.SmartID (\(method):)\n" +
                "Response: \n" + String(data: data!, encoding: .utf8)!
            )
#endif
            EncoderDecoder().decode(data: data!, completionHandler: { response in completionHandler(.success(response)) })
        }.resume()
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning().certificatePinning(trustedCertificates: trustedCerts ?? [""], challenge: challenge, completionHandler: completionHandler)
    }
}

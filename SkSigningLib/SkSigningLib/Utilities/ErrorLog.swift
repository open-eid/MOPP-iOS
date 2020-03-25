//
//  ErrorLog.swift
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

class ErrorLog {
    internal static func errorLog(forMethod: String, httpResponse: HTTPURLResponse?, error: MobileIDError, extraInfo: String) {
        guard let response = httpResponse else {
            return NSLog("\(forMethod) Error: \(error)\n" +
                "Error description: \(error.mobileIDErrorDescription ?? "Unable to get error description")\n" +
                extraInfo
            )
        }
        NSLog("\(forMethod) response code: \(response.statusCode)\n" +
            "Error: \(error)\n" +
            "Error description: \(error.mobileIDErrorDescription ?? "Unable to get error description")\n" +
            "URL: \(response.url?.absoluteString ?? "Unable to get URL")\n" +
            extraInfo
        )
    }
}



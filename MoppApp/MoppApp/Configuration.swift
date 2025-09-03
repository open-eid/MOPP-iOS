//
//  Configuration.swift
//  MoppApp
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

internal struct MOPPConfiguration: Decodable {
    internal struct MetaInf: Decodable {
        let URL: String
        let DATE: String
        let SERIAL: Int
        let VER: Int
    }

    let METAINF: MetaInf
    let TSLURL: String
    let SIVAURL: String
    let TSAURL: String
    let LDAPPERSONURL: URL
    let LDAPPERSONURLS: [URL]?
    let LDAPCORPURL: URL
    let LDAPCERTS: [Data]
    let TSLCERTS: [Data]
    let OCSPISSUERS: [String: String]
    let MIDPROXYURL: String
    let MIDSKURL: String
    let SIDV2PROXYURL: String
    let SIDV2SKURL: String
    let CERTBUNDLE: [Data]

    private enum CodingKeys: String, CodingKey {
        case TSLURL = "TSL-URL"
        case SIVAURL = "SIVA-URL"
        case METAINF = "META-INF"
        case TSAURL = "TSA-URL"
        case LDAPPERSONURL = "LDAP-PERSON-URL"
        case LDAPPERSONURLS = "LDAP-PERSON-URLS"
        case LDAPCORPURL = "LDAP-CORP-URL"
        case LDAPCERTS = "LDAP-CERTS"
        case TSLCERTS = "TSL-CERTS"
        case OCSPISSUERS = "OCSP-URL-ISSUER"
        case MIDPROXYURL = "MID-PROXY-URL"
        case MIDSKURL = "MID-SK-URL"
        case SIDV2PROXYURL = "SIDV2-PROXY-URL"
        case SIDV2SKURL = "SIDV2-SK-URL"
        case CERTBUNDLE = "CERT-BUNDLE"
    }

    init(json: String) throws {
        do {
            self = try JSONDecoder().decode(MOPPConfiguration.self, from: Data(json.utf8))
        } catch {
            printLog("Error decoding data: \(error.localizedDescription)")
            throw error
        }
    }
}


public class Configuration {
    static var moppConfig: MOPPConfiguration?

    static func getConfiguration() -> MOPPConfiguration {
        return moppConfig!
    }
}

internal struct DefaultMoppConfiguration: Codable {

    let CENTRALCONFIGURATIONSERVICEURL: String
    let UPDATEINTERVAL: Int
    let UPDATEDATE: String
    let VERSIONSERIAL: Int
    let TSLURL: String
    
    private enum CodingKeys: String, CodingKey {
        case CENTRALCONFIGURATIONSERVICEURL = "centralConfigurationServiceUrl"
        case UPDATEINTERVAL = "updateInterval"
        case UPDATEDATE = "updateDate"
        case VERSIONSERIAL = "versionSerial"
        case TSLURL = "tslUrl"
    }

    init(json: String) throws {
        do {
            self = try JSONDecoder().decode(DefaultMoppConfiguration.self, from: Data(json.utf8))
        } catch {
            printLog("Error decoding data: \(error.localizedDescription)")
            throw error
        }
    }
}

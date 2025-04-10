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
    let TSLURL: String
    let SIVAURL: String
    let METAINF: MOPPMetaInf
    let TSAURL: String
    let LDAPPERSONURL: String
    let LDAPCORPURL: String
    let TSLCERTS: [Data]
    let LDAPCERTS: [String]
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
        case LDAPCORPURL = "LDAP-CORP-URL"
        case TSLCERTS = "TSL-CERTS"
        case LDAPCERTS = "LDAP-CERTS"
        case OCSPISSUERS = "OCSP-URL-ISSUER"
        case MIDPROXYURL = "MID-PROXY-URL"
        case MIDSKURL = "MID-SK-URL"
        case SIDV2PROXYURL = "SIDV2-PROXY-URL"
        case SIDV2SKURL = "SIDV2-SK-URL"
        case CERTBUNDLE = "CERT-BUNDLE"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        TSLURL = try container.decode(String.self, forKey: .TSLURL)
        SIVAURL = try container.decode(String.self, forKey: .SIVAURL)
        METAINF = try container.decode(MOPPMetaInf.self, forKey: .METAINF)
        TSAURL = try container.decode(String.self, forKey: .TSAURL)
        LDAPPERSONURL = try container.decode(String.self, forKey: .LDAPPERSONURL)
        LDAPCORPURL = try container.decode(String.self, forKey: .LDAPCORPURL)
        TSLCERTS = try container.decode([Data].self, forKey: .TSLCERTS)
        LDAPCERTS = try container.decodeIfPresent([String].self, forKey: .LDAPCERTS) ?? []
        OCSPISSUERS = try container.decode([String: String].self, forKey: .OCSPISSUERS)
        MIDPROXYURL = try container.decode(String.self, forKey: .MIDPROXYURL)
        MIDSKURL = try container.decode(String.self, forKey: .MIDSKURL)
        SIDV2PROXYURL = try container.decode(String.self, forKey: .SIDV2PROXYURL)
        SIDV2SKURL = try container.decode(String.self, forKey: .SIDV2SKURL)
        CERTBUNDLE = try container.decode([Data].self, forKey: .CERTBUNDLE)
    }
}

internal struct MOPPMetaInf: Decodable {
    let URL: String
    let DATE: String
    let SERIAL: Int
    let VER: Int
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
    
    private enum DefaultMoppConfigurationType: String, CodingKey {
        case CENTRALCONFIGURATIONSERVICEURL = "centralConfigurationServiceUrl"
        case UPDATEINTERVAL = "updateInterval"
        case UPDATEDATE = "updateDate"
        case VERSIONSERIAL = "versionSerial"
        case TSLURL = "tslUrl"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DefaultMoppConfigurationType.self)
        CENTRALCONFIGURATIONSERVICEURL = try container.decode(String.self, forKey: .CENTRALCONFIGURATIONSERVICEURL)
        UPDATEINTERVAL = try container.decode(Int.self, forKey: .UPDATEINTERVAL)
        UPDATEDATE = try container.decode(String.self, forKey: .UPDATEDATE)
        VERSIONSERIAL = try container.decode(Int.self, forKey: .VERSIONSERIAL)
        TSLURL = try container.decode(String.self, forKey: .TSLURL)
    }
}

//
//  Configuration.swift
//  MoppApp
//
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
import ASN1Decoder

internal struct MOPPConfiguration: Codable {
    var TSLURL: String
    let SIVAURL: String
    let METAINF: MOPPMetaInf
    let TSAURL: String
    let LDAPPERSONURL: String
    let LDAPCORPURL: String
    let TSLCERTS: Array<String>
    let OCSPISSUERS: [String: String]
    let MIDPROXYURL: String
    let MIDSKURL: String
    let SIDPROXYURL: String
    let SIDSKURL: String
    let SIDV2PROXYURL: String
    let SIDV2SKURL: String
    let CERTBUNDLE: Array<String>
    
    private enum MOPPConfigurationType: String, CodingKey {
        case TSLURL = "TSL-URL"
        case SIVAURL = "SIVA-URL"
        case METAINF = "META-INF"
        case TSAURL = "TSA-URL"
        case LDAPPERSONURL = "LDAP-PERSON-URL"
        case LDAPCORPURL = "LDAP-CORP-URL"
        case TSLCERTS = "TSL-CERTS"
        case OCSPISSUERS = "OCSP-URL-ISSUER"
        case MIDPROXYURL = "MID-PROXY-URL"
        case MIDSKURL = "MID-SK-URL"
        case SIDPROXYURL = "SID-PROXY-URL"
        case SIDSKURL = "SID-SK-URL"
        case SIDV2PROXYURL = "SIDV2-PROXY-URL"
        case SIDV2SKURL = "SIDV2-SK-URL"
        case CERTBUNDLE = "CERT-BUNDLE"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MOPPConfigurationType.self)
        TSLURL = try container.decode(String.self, forKey: .TSLURL)
        SIVAURL = try container.decode(String.self, forKey: .SIVAURL)
        METAINF = try container.decode(MOPPMetaInf.self, forKey: .METAINF)
        TSAURL = try container.decode(String.self, forKey: .TSAURL)
        LDAPPERSONURL = try container.decode(String.self, forKey: .LDAPPERSONURL)
        LDAPCORPURL = try container.decode(String.self, forKey: .LDAPCORPURL)
        TSLCERTS = try container.decode([String].self, forKey: .TSLCERTS)
        OCSPISSUERS = try container.decode([String: String].self, forKey: .OCSPISSUERS)
        MIDPROXYURL = try container.decode(String.self, forKey: .MIDPROXYURL)
        MIDSKURL = try container.decode(String.self, forKey: .MIDSKURL)
        SIDPROXYURL = try container.decode(String.self, forKey: .SIDPROXYURL)
        SIDSKURL = try container.decode(String.self, forKey: .SIDSKURL)
        SIDV2PROXYURL = try container.decodeIfPresent(String.self, forKey: .SIDV2PROXYURL) ?? ""
        SIDV2SKURL = try container.decodeIfPresent(String.self, forKey: .SIDV2SKURL) ?? ""
        CERTBUNDLE = try container.decode([String].self, forKey: .CERTBUNDLE)
    }
}

internal struct MOPPMetaInf: Codable {
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


public class MoppConfiguration {
    static var sivaUrl: String?
    static var tslUrl: String?
    static var tslCerts: Array<String>?
    static var tsaUrl: String?
    static var ocspIssuers: [String: String]?
    static var certBundle: Array<String>?
    static var tsaCert: String?
    
    static func getMoppLibConfiguration() -> MoppLibConfiguration {
        return MoppLibConfiguration(configuration: sivaUrl, tslurl: tslUrl, tslcerts: tslCerts, tsaurl: tsaUrl, ocspissuers: ocspIssuers, certbundle: certBundle, tsacert: tsaCert)
    }
}

public class MoppLDAPConfiguration {
    static var ldapPersonUrl: String?
    static var ldapCorpUrl: String?
    
    static func getMoppLDAPConfiguration() -> MoppLdapConfiguration {
        return MoppLdapConfiguration(ldapConfiguration: ldapPersonUrl, ldapcorpurl: ldapCorpUrl)
    }
}

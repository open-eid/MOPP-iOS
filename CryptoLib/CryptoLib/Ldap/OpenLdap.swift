//
//  OpenLdap.swift
//  CryptoLib
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
import LDAP

typealias LDAP = OpaquePointer
typealias LDAPMessage = OpaquePointer

public class OpenLdap: NSObject {
    private override init() {}

    @objc static public func search(identityCode: String, configuration: MoppLdapConfiguration, withCertificate cert: String?) -> [LDAPResponse] {
        if configuration.LDAPCERTS.isEmpty {
            var result = search(identityCode: identityCode, url: configuration.LDAPPERSONURL, certificatePath: nil)

            if result.isEmpty {
                result = search(identityCode: identityCode, url: configuration.LDAPCORPURL, certificatePath: nil)
            }
            return result
        }

        if isPersonalCode(identityCode) {
            print("Searching with personal code from LDAP")
            return search(identityCode: identityCode, url: configuration.LDAPPERSONURL, certificatePath: cert)
        } else {
            print("Searching with corporation keyword from LDAP")
            return search(identityCode: identityCode, url: configuration.LDAPCORPURL, certificatePath: cert)
        }
    }

    static private func search(identityCode: String, url: String, certificatePath: String?) -> [LDAPResponse] {
        let secureLdap = url.lowercased().hasPrefix("ldaps")
        if secureLdap {
            if let certificatePath = certificatePath, !certificatePath.isEmpty {
                guard setLdapOption(option: LDAP_OPT_X_TLS_CACERTFILE, value: certificatePath) else { return [] }
            } else {
                guard let bundlePath = Bundle(for: OpenLdap.self).resourcePath else { return [] }
                guard setLdapOption(option: LDAP_OPT_X_TLS_CACERTDIR, value: bundlePath) else { return [] }
            }
            var ldapConnectionReset = 0
            let result = ldap_set_option(nil, LDAP_OPT_X_TLS_NEWCTX, &ldapConnectionReset)
            guard result == LDAP_SUCCESS else {
                print("ldap_set_option(LDAP_OPT_X_TLS_NEWCTX) failed: \(String(cString: ldap_err2string(result)))")
                return []
            }
        }

        var ldap: LDAP?
        let ldapReturnCode = ldap_initialize(&ldap, url.cString(using: .utf8))
        defer {
            if let ldap = ldap { ldap_unbind_ext_s(ldap, nil, nil) }
        }
        guard ldapReturnCode == LDAP_SUCCESS else {
            print("Failed to initialize LDAP: \(String(cString: ldap_err2string(ldapReturnCode)))")
            return []
        }

        var ldapVersion = LDAP_VERSION3
        let result = ldap_set_option(ldap, LDAP_OPT_PROTOCOL_VERSION, &ldapVersion)
        guard result == LDAP_SUCCESS else {
            print("ldap_set_option(PROTOCOL_VERSION) failed: \(String(cString: ldap_err2string(result)))")
            return []
        }

        let filter = if isPersonalCode(identityCode) {
            "(serialNumber=\(secureLdap ? "PNOEE-" : "")\(identityCode))"
        } else if identityCode.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil {
            "(serialNumber=\(identityCode))"
        } else {
            "(cn=*\(identityCode)*)"
        }
        var msg: LDAPMessage?
        print("Searching from LDAP. Url: \(url) \(filter)")
        ldap_search_ext_s(ldap, "c=EE", LDAP_SCOPE_SUBTREE, filter, nil, 0, nil, nil, nil, 0, &msg)

        if let msg = msg {
            defer { ldap_msgfree(msg) }
            return LDAPResponse.from(ldap: ldap!, msg: msg)
        }

        return []
    }

    static private func setLdapOption(option: Int32, value: String) -> Bool {
        let result = ldap_set_option(nil, option, value.cString(using: .utf8))
        if result != LDAP_SUCCESS {
            print("ldap_set_option failed: \(String(cString: ldap_err2string(result)))")
            return false
        }
        return true
    }

    static private func isPersonalCode(_ inputString: String) -> Bool {
        return inputString.count == 11 && inputString.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}

//
//  LDAPResponse.swift
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

public class LDAPResponse: NSObject {
    @objc public var userCertificate: [Data] = []
    @objc public var cn: String = ""

    typealias BerElement = OpaquePointer

    init(ldap: LDAP, msg: LDAPMessage) {
        var ber: BerElement?
        var attrPointer = ldap_first_attribute(ldap, msg, &ber)
        while let attr = attrPointer {
            defer { ldap_memfree(attr) }
            let tag = String(cString: attr)
            switch tag {
            case "cn": cn = (LDAPResponse.values(ldap: ldap, msg: msg, tag: tag) as [String]).first ?? ""
            case "userCertificate;binary": userCertificate = LDAPResponse.values(ldap: ldap, msg: msg, tag: tag)
            default: break
            }
            attrPointer = ldap_next_attribute(ldap, msg, ber)
        }
        if let ber = ber {
            ber_free(ber, 0)
        }

        if let namePointer = ldap_get_dn(ldap, msg) {
            print("Result (\(userCertificate.count)) \(String(cString: namePointer))")
            ldap_memfree(namePointer)
        }
    }

    static func from(ldap: LDAP, msg: LDAPMessage) -> [LDAPResponse] {
        var result: [LDAPResponse] = []
        var message = ldap_first_message(ldap, msg)
        while let currentMessage = message {
            if ldap_msgtype(currentMessage) == LDAP_RES_SEARCH_ENTRY {
                let response = LDAPResponse(ldap: ldap, msg: currentMessage)
                if !response.userCertificate.isEmpty {
                    result.append(response)
                }
            }
            message = ldap_next_message(ldap, currentMessage)
        }
        return result
    }

    static func values<T>(ldap: LDAP, msg: LDAPMessage, tag: String) -> [T] {
        var result: [T] = []
        guard let bvals = ldap_get_values_len(ldap, msg, tag) else {
            return result
        }
        defer { ldap_value_free_len(bvals) }

        var i = 0
        while let bval = bvals[i] {
            let value = bval.pointee.bv_val
            let length = bval.pointee.bv_len
            if T.self == Data.self {
                result.append(Data(bytes: value!, count: Int(length)) as! T)
            } else if T.self == String.self, let stringValue = String(validatingUTF8: value!) {
                result.append(stringValue as! T)
            }
            i += 1
        }
        return result
    }
}

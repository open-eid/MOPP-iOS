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

private import LDAP
import ASN1Decoder

public class OpenLdap {
    typealias LDAP = OpaquePointer
    typealias LDAPMessage = OpaquePointer
    typealias BerElement = OpaquePointer

    enum KeyUsage: Int {
        case digitalSignature = 0
        case nonRepudiation = 1
        case keyEncipherment = 2
        case dataEncipherment = 3
        case keyAgreement = 4
        case keyCertSign = 5
        case cRLSign = 6
        case encipherOnly = 7
        case decipherOnly = 8
    }

    enum SearchType {
        case personalCode(String)
        case registryCode(String)
        case other(String)

        init(from: String) {
            self = switch (from.allSatisfy({ $0.isNumber }), from.count) {
            case (true, 11): .personalCode(from)
            case (true, 8): .registryCode(from)
            default: .other(from)
            }
        }

        var filter: String {
            switch self {
            case .registryCode(let code): "(serialNumber=\(escape(code))"
            case .personalCode(let code): "(serialNumber=PNOEE-\(escape(code))"
            case .other(let cn): "(cn=*\(escape(cn))*)"
            }
        }

        func escape(_ data: String) -> String {
            data
               .replacingOccurrences(of: "\\", with: "\\\\")
               .replacingOccurrences(of: "(", with: "\\(")
               .replacingOccurrences(of: ")", with: "\\)")
               .replacingOccurrences(of: "*", with: "\\*")
        }
    }

    static public func search(identityCode: String) -> (
        addressees: [Addressee],
        tooManyResults: Bool
    ) {
        var filePath: String? = nil
        if let ldapCertFilePath = MoppLdapConfiguration.ldapCertsPath {
            if FileManager.default.fileExists(atPath: ldapCertFilePath) {
                filePath = ldapCertFilePath
            } else {
                print("File ldapCerts.pem does not exist at directory path: \(ldapCertFilePath)")
                filePath = nil
            }
        }

        let searchType = SearchType(from: identityCode)
        if case .personalCode = searchType {
            print("Searching with personal code from LDAP")
            var result = [Addressee]()
            var tooManyResults = false
            for url in MoppLdapConfiguration.ldapPersonURLS {
                let (addresses, found) = search(searchType: searchType, url: url, certificatePath: filePath)
                result.append(contentsOf: addresses)
                if found >= 50 {
                    tooManyResults = true
                }
            }
            return (result, tooManyResults)
        } else {
            print("Searching with corporation keyword from LDAP")
            let (addresses, found) = search(searchType: searchType, url: MoppLdapConfiguration.ldapCorpURL, certificatePath: filePath)
            return (addresses, found >= 50)
        }
    }

    static private func search(searchType: SearchType, url: URL, certificatePath: String?) -> (addressees: [Addressee], totalAddressees: Int) {
        if url.scheme?.lowercased() == "ldaps" {
            if let certificatePath = certificatePath, !certificatePath.isEmpty {
                guard setLdapOption(option: LDAP_OPT_X_TLS_CACERTFILE, value: certificatePath) else { return ([], 0) }
            } else {
                guard let bundlePath = Bundle(for: OpenLdap.self).resourcePath else { return ([], 0) }
                guard setLdapOption(option: LDAP_OPT_X_TLS_CACERTDIR, value: bundlePath) else { return ([], 0) }
            }
            var ldapConnectionReset = 0
            let result = ldap_set_option(nil, LDAP_OPT_X_TLS_NEWCTX, &ldapConnectionReset)
            guard result == LDAP_SUCCESS else {
                print("ldap_set_option(LDAP_OPT_X_TLS_NEWCTX) failed: \(String(cString: ldap_err2string(result)))")
                return ([], 0)
            }
        }

        var ldap: LDAP?
        let host: String
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.path = ""
            components.query = nil
            components.fragment = nil
            host = components.string!
        } else {
            host = url.absoluteString
        }
        var ldapReturnCode = ldap_initialize(&ldap, host)
        defer {
            if let ldap = ldap { ldap_destroy(ldap) }
        }
        guard ldapReturnCode == LDAP_SUCCESS else {
            print("Failed to initialize LDAP: \(String(cString: ldap_err2string(ldapReturnCode)))")
            return ([], 0)
        }

        var ldapVersion = LDAP_VERSION3
        ldapReturnCode = ldap_set_option(ldap, LDAP_OPT_PROTOCOL_VERSION, &ldapVersion)
        guard ldapReturnCode == LDAP_SUCCESS else {
            print("ldap_set_option(PROTOCOL_VERSION) failed: \(String(cString: ldap_err2string(ldapReturnCode)))")
            return ([], 0)
        }

        var dn = url.path
        if dn.isEmpty {
            dn = "c=EE"
        } else {
            dn.remove(at: dn.startIndex)
        }
        print("Searching from LDAP. Url: \(url) \(dn) \(searchType.filter)")
        var msgId: Int32 = 0
        var attr = Array("userCertificate;binary".utf8CString)
        ldapReturnCode = attr.withUnsafeMutableBufferPointer { attr in
            var attrs = [attr.baseAddress, nil]
            return attrs.withUnsafeMutableBufferPointer { attrs in
                ldap_search_ext(ldap, dn, LDAP_SCOPE_SUBTREE, searchType.filter, attrs.baseAddress, 0, nil, nil, nil, 0, &msgId)
            }
        }

        guard ldapReturnCode == LDAP_SUCCESS else {
            print("ldap_search_ext failed: \(String(cString: ldap_err2string(ldapReturnCode)))")
            return ([], 0)
        }

        var result = [Addressee]()
        var totalAddressees = 0
        var msg: LDAPMessage? = nil
        while !Task.isCancelled {
            var tv = timeval(tv_sec: 0, tv_usec: 100_000)
            ldapReturnCode = ldap_result(ldap, msgId, LDAP_MSG_ONE, &tv, &msg)

            defer { if let msg = msg { ldap_msgfree(msg) } }
            switch ldapReturnCode {
            case Int32(LDAP_RES_SEARCH_ENTRY):
                let addressees = attributes(ldap: ldap!, msg: msg!)
                result.append(contentsOf: addressees)
                totalAddressees += 1
                break
            case Int32(LDAP_RES_SEARCH_RESULT):
                return (addressees: result, totalAddressees: totalAddressees)
            case Int32(LDAP_SUCCESS):
                break
            default:
                print("ldap_result failed: \(String(cString: ldap_err2string(ldapReturnCode)))")
                return (addressees: result, totalAddressees: totalAddressees)
            }
        }

        ldap_abandon_ext(ldap, msgId, nil, nil)

        return (addressees: result, totalAddressees: totalAddressees)
    }

    static private func setLdapOption(option: Int32, value: String) -> Bool {
        let result = ldap_set_option(nil, option, value)
        if result != LDAP_SUCCESS {
            print("ldap_set_option failed: \(String(cString: ldap_err2string(result)))")
            return false
        }
        return true
    }

    static private func attributes(ldap: LDAP, msg: LDAPMessage) -> [Addressee] {
        var result = [Addressee]()
        var message = ldap_first_message(ldap, msg)
        while let currentMessage = message {
            guard !Task.isCancelled else { break }
            if ldap_msgtype(currentMessage) == LDAP_RES_SEARCH_ENTRY {
                var ber: BerElement?
                var attrPointer = ldap_first_attribute(ldap, currentMessage, &ber)
                defer {
                    if let ber = ber { ber_free(ber, 0) }
                }
                while let attr = attrPointer {
                    defer { ldap_memfree(attr) }
                    result.append(contentsOf: values(ldap: ldap, msg: currentMessage, tag: String(cString: attr)))
                    attrPointer = ldap_next_attribute(ldap, currentMessage, ber)
                }

                if let namePointer = ldap_get_dn(ldap, currentMessage) {
                    print("Result (\(result.count)) \(String(cString: namePointer))")
                    ldap_memfree(namePointer)
                }
            }
            message = ldap_next_message(ldap, currentMessage)
        }
        return result
    }

    static private func values(ldap: LDAP, msg: LDAPMessage, tag: String) -> [Addressee] {
        var result = [Addressee]()
        guard let bvals = ldap_get_values_len(ldap, msg, tag) else {
            return result
        }
        defer { ldap_value_free_len(bvals) }

        var i = 0
        while let bval = bvals[i] {
            guard !Task.isCancelled else { break }
            let data = Data(bytes: bval.pointee.bv_val, count: Int(bval.pointee.bv_len))
            i += 1
            guard let x509 = try? X509Certificate(der: data) else {
                continue
            }
            let type = x509.certType()
            if x509.keyUsage[KeyUsage.keyEncipherment.rawValue] || x509.keyUsage[KeyUsage.keyAgreement.rawValue],
               !x509.extendedKeyUsage.contains(OID.serverAuth.rawValue),
               type != .ESealType || !x509.extendedKeyUsage.contains(OID.clientAuth.rawValue),
               type != .MobileIDType && type != .UnknownType {
                let cn = x509.subject(oid: OID.commonName)?.joined(separator: ",") ?? ""
                let serialNumber = x509.subject(oid: OID.serialNumber)?.joined(separator: ",") ?? ""
                let split = cn.split(separator: ",").map { String($0) }
                let addressee = Addressee()
                if split.count == 3 {
                    addressee.surname = split[0]
                    addressee.givenName = split[1]
                    addressee.identifier = split[2]
                } else {
                    addressee.identifier = cn
                }
                addressee.serialNumber = serialNumber
                addressee.cert = data
                addressee.validTo = x509.notAfter ?? Date()
                result.append(addressee)
            }
        }
        return result
    }
}

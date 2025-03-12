//
//  MoppLibConfiguration.swift
//  MoppLib
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

@objcMembers
public class MoppLibConfiguration: NSObject {

    public var sivaURL: String
    public var tslURL: String
    public var tslCerts: [String]
    public var ldapCerts: [String]
    public var tsaURL: String
    public var ocspIssuers: [String: String]
    public var certBundle: [String]
    public var tsaCert: String

    public init(sivaURL: String, tslURL: String, tslCerts: [String], ldapCerts: [String], tsaURL: String, ocspIssuers: [String : String], certBundle: [String], tsaCert: String) {
        self.sivaURL = sivaURL
        self.tslURL = tslURL
        self.tslCerts = tslCerts
        self.ldapCerts = ldapCerts
        self.tsaURL = tsaURL
        self.ocspIssuers = ocspIssuers
        self.certBundle = certBundle
        self.tsaCert = tsaCert
    }
}

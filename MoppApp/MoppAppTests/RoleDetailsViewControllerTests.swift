//
//  RoleDetailsViewControllerTests.swift
//  MoppAppTests
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
import XCTest
import MoppLib
@testable import MoppApp

class RoleDetailsViewControllerTests: XCTestCase {
    
    var viewController: RoleDetailsViewController!
    var window: UIWindow!
    var moppLibSignature: MoppLibSignature? = MoppLibSignature()
    
    override func tearDown() {
        window = nil
        super.tearDown()
    }
    
    override func setUp() {
        super.setUp()
        window = UIWindow()
        setupRoleDetails()
        setupRoleDetailsViewController()
    }
    
    func testViewControllerIsNotEmpty() {
        XCTAssertNotNil(self.viewController)
    }
    
    func testRoleDataIsNotMissing() {
        XCTAssertNotNil(self.moppLibSignature?.roleAndAddressData)
    }
    
    func testRoleDetailsViewDoesNotThrowException() {
        if let roleVC = self.viewController {
            roleVC.roleDetails = self.moppLibSignature?.roleAndAddressData
            roleVC.loadView()
            roleVC.viewDidLoad()
            XCTAssertNoThrow(EXC_BAD_ACCESS)
            XCTAssertNoThrow(EXC_CRASH)
        } else {
            XCTFail("Unable to load RoleDetailsViewController")
        }
    }
    
    func testRoleDetailsDataNotMissing() {
        if let roleVC = self.viewController {
            roleVC.roleDetails = self.moppLibSignature?.roleAndAddressData
            
            XCTAssertNotNil(roleVC.roleDetails?.roles)
            XCTAssertNotNil(roleVC.roleDetails?.city)
            XCTAssertNotNil(roleVC.roleDetails?.state)
            XCTAssertNotNil(roleVC.roleDetails?.country)
            XCTAssertNotNil(roleVC.roleDetails?.zip)
        } else {
            XCTFail("Unable to load RoleDetailsViewController")
        }
    }
    
    func testRoleDetailsDataMissing() {
        if let roleVC = self.viewController {
            XCTAssertNil(roleVC.roleDetails?.roles)
            XCTAssertNil(roleVC.roleDetails?.city)
            XCTAssertNil(roleVC.roleDetails?.state)
            XCTAssertNil(roleVC.roleDetails?.country)
            XCTAssertNil(roleVC.roleDetails?.zip)
        } else {
            XCTFail("Unable to load RoleDetailsViewController")
        }
    }
    
    func testRoleDetailsDataValid() {
        if let roleVC = self.viewController {
            roleVC.roleDetails = self.moppLibSignature?.roleAndAddressData
            
            XCTAssertEqual(roleVC.roleDetails?.roles, self.moppLibSignature?.roleAndAddressData.roles)
            XCTAssertEqual(roleVC.roleDetails?.city, self.moppLibSignature?.roleAndAddressData.city)
            XCTAssertEqual(roleVC.roleDetails?.state, self.moppLibSignature?.roleAndAddressData.state)
            XCTAssertEqual(roleVC.roleDetails?.country, self.moppLibSignature?.roleAndAddressData.country)
            XCTAssertEqual(roleVC.roleDetails?.zip, self.moppLibSignature?.roleAndAddressData.zip)
        } else {
            XCTFail("Unable to load RoleDetailsViewController")
        }
    }
    
    func testRoleDetailsDataNotInvalid() {
        if let roleVC = self.viewController {
            roleVC.roleDetails = self.moppLibSignature?.roleAndAddressData
            
            XCTAssertNotEqual(roleVC.roleDetails?.roles, ["Invalid role 1", "Invalid role 2"])
            XCTAssertNotEqual(roleVC.roleDetails?.city, "Invalid city")
            XCTAssertNotEqual(roleVC.roleDetails?.state, "Invalid state")
            XCTAssertNotEqual(roleVC.roleDetails?.country, "Invalid country")
            XCTAssertNotEqual(roleVC.roleDetails?.zip, "Invalid zip")
        } else {
            XCTFail("Unable to load RoleDetailsViewController")
        }
    }
    
    func testRoleDetailsDataEmpty() {
        setupEmptyRoleDetails()
        
        if let roleVC = self.viewController {
            roleVC.roleDetails = self.moppLibSignature?.roleAndAddressData
            
            XCTAssertNil(roleVC.roleDetails?.roles)
            XCTAssertNil(roleVC.roleDetails?.city)
            XCTAssertNil(roleVC.roleDetails?.state)
            XCTAssertNil(roleVC.roleDetails?.country)
            XCTAssertNil(roleVC.roleDetails?.zip)
        } else {
            XCTFail("Unable to load RoleDetailsViewController")
        }
    }
    
    func testRoleDetailsDataEmptyNotInvalid() {
        setupEmptyRoleDetails()
        
        if let roleVC = self.viewController {
            roleVC.roleDetails = self.moppLibSignature?.roleAndAddressData
            
            XCTAssertNotEqual(roleVC.roleDetails?.roles, ["Invalid role 1", "Invalid role 2"])
            XCTAssertNotEqual(roleVC.roleDetails?.city, "Invalid city")
            XCTAssertNotEqual(roleVC.roleDetails?.state, "Invalid state")
            XCTAssertNotEqual(roleVC.roleDetails?.country, "Invalid country")
            XCTAssertNotEqual(roleVC.roleDetails?.zip, "Invalid zip")
        } else {
            XCTFail("Unable to load RoleDetailsViewController")
        }
    }
    
    func setupRoleDetailsViewController() {
        self.viewController = UIStoryboard.container.instantiateViewController(of: RoleDetailsViewController.self)
    }
    
    func setupRoleDetails() {
        self.moppLibSignature?.roleAndAddressData = MoppLibRoleAddressData(
            roles: ["Test role 1", "Test role 2"],
            city: "Test city",
            state: "Test state",
            country: "Test country",
            zip: "Test zip")
    }
    
    func setupEmptyRoleDetails() {
        self.moppLibSignature?.roleAndAddressData = MoppLibRoleAddressData(
            roles: nil,
            city: nil,
            state: nil,
            country: nil,
            zip: nil)
    }
}

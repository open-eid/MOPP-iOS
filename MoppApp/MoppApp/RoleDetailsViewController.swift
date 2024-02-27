//
//  RoleDetailsViewController.swift
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

class RoleDetailsViewController: MoppViewController {
    
    @IBOutlet weak var roleTitle: UILabel!
    @IBOutlet weak var roleValue: UILabel!
    
    @IBOutlet weak var cityTitle: UILabel!
    @IBOutlet weak var cityValue: UILabel!
    
    @IBOutlet weak var stateTitle: UILabel!
    @IBOutlet weak var stateValue: UILabel!
    
    @IBOutlet weak var countryTitle: UILabel!
    @IBOutlet weak var countryValue: UILabel!
    
    @IBOutlet weak var zipTitle: UILabel!
    @IBOutlet weak var zipValue: UILabel!
    
    var roleDetails: MoppLibRoleAddressData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationItemForPushedViewController(title: L(.roleAndAddress))
        
        roleTitle.text = L(.roleAndAddressRoleTitle)
        roleValue.text = roleDetails?.roles.joined(separator: ", ") ?? ""
        
        cityTitle.text = L(.roleAndAddressCityTitle)
        cityValue.text = roleDetails?.city ?? ""
        
        stateTitle.text = L(.roleAndAddressStateTitle)
        stateValue.text = roleDetails?.state ?? ""
        
        countryTitle.text = L(.roleAndAddressCountryTitle)
        countryValue.text = roleDetails?.country ?? ""
        
        zipTitle.text = L(.roleAndAddressZipTitle)
        zipValue.text = roleDetails?.zip ?? ""
    }
}

//
//  AboutViewController.swift
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

import UIKit

struct LibraryInfo {
    var name: String
    var license: String
    var licenseURL: String
}

enum Section {
    case header
    case appInfo
    case licenses
}

class AboutViewController: MoppViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let sections: [Section] = [.header, .appInfo, .licenses]
    
    let libraries: [LibraryInfo] = [
        LibraryInfo(name: "libdigidocpp", license: "GNU Lesser General Public License (LGPL) version 2.1", licenseURL: "https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html"),
        LibraryInfo(name: "Xerces-C++", license: "Apache License version 2.0", licenseURL: "http://www.apache.org/licenses/LICENSE-2.0.html"),
        LibraryInfo(name: "Xalan-C++", license: "Apache License version 2.0", licenseURL: "http://www.apache.org/licenses/LICENSE-2.0.html"),
        LibraryInfo(name: "XML-Security-C", license: "Apache License version 2.0", licenseURL: "http://www.apache.org/licenses/LICENSE-2.0.html"),
        LibraryInfo(name: "XSD", license: "GNU General Public License, version 2", licenseURL: "https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html"),
        LibraryInfo(name: "OpenSSL", license: "OpenSSL License", licenseURL: "https://www.openssl.org/source/license.txt"),
        LibraryInfo(name: "zlib", license: "zlib License", licenseURL: "https://zlib.net/zlib_license.html"),
        LibraryInfo(name: "cdoc", license: "GNU Lesser General Public License (LGPL) version 2.1", licenseURL: "https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html"),
        LibraryInfo(name: "OpenLDAP", license: "The OpenLDAP Public License", licenseURL: "https://www.openldap.org/software/release/license.html"),
        LibraryInfo(name: "ACS ACR3901U", license: "User terms and conditions", licenseURL: "https://www.acs.com.hk/en/"),
        LibraryInfo(name: "Feitian R301/iR301U", license: "User terms and conditions", licenseURL: "https://www.ftsafe.com/"),
        LibraryInfo(name: "swift-sh", license: "Unlicense (Public Domain)", licenseURL: "https://github.com/mxcl/swift-sh/blob/master/LICENSE.md"),
        LibraryInfo(name: "ZipFoundation", license: "MIT License", licenseURL: "https://github.com/weichsel/ZIPFoundation/blob/main/LICENSE"),
        LibraryInfo(name: "mid-rest-java-client", license: "MIT License", licenseURL: "https://github.com/SK-EID/mid-rest-java-client/blob/master/LICENSE"),
        LibraryInfo(name: "ILPDFKit", license: "MIT License", licenseURL: "https://github.com/derekblair/ILPDFKit/blob/master/LICENSE")
    ]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.allowsFocus = true
        tableView.selectionFollowsFocus = true
        
        tableView.separatorStyle = .none
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .header, .appInfo:
            return 1
        default:
            return libraries.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .header:
            let cell = tableView.dequeueReusableCell(withType: AboutHeaderCell.self, for: indexPath)!
            cell.delegate = self
            cell.populate()
            cell.selectionStyle = .none
            return cell
        case .appInfo:
            let cell = tableView.dequeueReusableCell(withType: AppInfoCell.self, for: indexPath)!
            cell.populate()
            cell.selectionStyle = .none
            return cell
        case .licenses:
            let cell = tableView.dequeueReusableCell(withType: LicensesCell.self, for: indexPath)!
            let library = libraries[indexPath.row]
            cell.populate(dependencyName: library.name, dependencyLicense: library.license, dependencyUrl: library.licenseURL)
            cell.selectionStyle = .none
            return cell
        }
    }
}

extension AboutViewController: SettingsHeaderCellDelegate {
    func didDismissSettings() {
        dismiss(animated: true, completion: nil)
    }
}

//
//  ContainerViewController.swift
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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


class ContainerViewController : MoppViewController {

    @IBOutlet weak var tableView: UITableView!

    enum Section {
        case error
        case signatures
        case timestamp
        case files
        case header
    }

    var sectionCellHeight: [Section: CGFloat] = [
        .error          : 44,
        .signatures     : 60,
        .timestamp      : 60,
        .files           : 44,
        .header         : 58
        ]

    var isSectionRowEditable: [Section: Bool] = [
        .error          : false,
        .signatures     : true,
        .timestamp      : false,
        .files           : true,
        .header         : false
        ]

    var sectionHeaderTitle: [Section: String] = [
        .files           : "Files",
        .timestamp      : "Container timestamp",
        .signatures     : "Signatures"
        ]

    private static let sectionsWithError: [Section] = [.error, .files, .signatures, .timestamp]
    private static let sectionsDefault: [Section] = [.files, .signatures, .timestamp]
    var sections: [Section] = ContainerViewController.sectionsDefault

    let mockFiles = ["Document 1.pdf", "Document 2.pdf", "Some important document.xdoc"]
    let mockTimestamp = ["KARL-MARTIN SINIJÄRV"]
    let mockSignatures = ["KARL-MARTIN SINIJÄRV", "PEETER PAKIRAAM", "VELLO VILJANDI"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOnce()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        errorHidden = false
    }
}

extension ContainerViewController {
    var errorHidden: Bool {
        get { return !sections.contains(.error) }
        set {
            sections = newValue ?
                ContainerViewController.sectionsDefault :
                ContainerViewController.sectionsWithError
            tableView.reloadData()
        }
    }
}

extension ContainerViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .error:
            return 1
        case .signatures:
            return mockSignatures.count
        case .timestamp:
            return mockTimestamp.count
        case .files:
            return mockFiles.count
        case .header:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        switch sections[indexPath.section] {
        case .error:
            let cell = tableView.dequeueReusableCell(withType: ContainerErrorCell.self, for: indexPath)!
            return cell
        case .signatures:
            let cell = tableView.dequeueReusableCell(withType: ContainerSignatureCell.self, for: indexPath)!
                cell.populate(name: mockSignatures[row], kind: .signature, colorTheme: (row == 0 ? .showInvalid : .showSuccess), showBottomBorder: row < mockSignatures.count - 1)
            return cell
        case .timestamp:
            let cell = tableView.dequeueReusableCell(withType: ContainerSignatureCell.self, for: indexPath)!
                cell.populate(name: mockTimestamp[row], kind: .timestamp, colorTheme: .neutral, showBottomBorder: row < mockTimestamp.count - 1)
            return cell
        case .files:
            let cell = tableView.dequeueReusableCell(withType: ContainerFileCell.self, for: indexPath)!
                cell.populate(name: mockFiles[row], showBottomBorder: row < mockFiles.count - 1)
            return cell
        case .header:
            let cell = tableView.dequeueReusableCell(withType: ContainerHeaderCell.self, for: indexPath)!
            return cell
        }
    }
}

extension ContainerViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return sectionCellHeight[sections[indexPath.section]]!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .error:
            break
        case .signatures:
            break
        case .timestamp:
            break;
        case .files:
            break
        case .header:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return isSectionRowEditable[sections[indexPath.section]]!
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section]
        if let title = sectionHeaderTitle[section] {
            if let header = MoppApp.instance.nibs[.containerElements]?.instantiate(withOwner: self, type: ContainerTableViewHeaderView.self) {
                header.populate(withTitle: title, showAddButton: section == .files || section == .signatures)
                return header
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        let section = sections[_section]
        if sectionHeaderTitle[section] != nil {
            return 60
        }
        return 0
    }
}

extension ContainerViewController {
    func setupOnce() {
        navigationItem.titleView = nil
        navigationItem.title = "Document 1.bdoc"
        let backBarButtonItem = UIBarButtonItem(image: UIImage(named: "navBarBack"), style: .plain, target: self, action: #selector(backAction))
        let rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "navBarShare"), style: .plain, target: self, action: #selector(backAction))
        navigationItem.setLeftBarButton(backBarButtonItem, animated: true)
        navigationItem.setRightBarButton(rightBarButtonItem, animated: true)
    }
}

extension ContainerViewController {
    @objc
    func backAction() {
        _ = navigationController?.popViewController(animated: true)
    }
}

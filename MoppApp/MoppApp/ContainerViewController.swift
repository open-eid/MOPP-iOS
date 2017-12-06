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

    var container: MoppLibContainer!
    var containerPath: String? = nil
    @IBOutlet weak var tableView: UITableView!

    enum Section {
        case error
        case signatures
        case timestamp
        case files
        case header
        case search
    }

    var sectionCellHeight: [Section: CGFloat] = [
        .error          : ContainerErrorCell.height,
        .signatures     : ContainerSignatureCell.height,
        .timestamp      : ContainerSignatureCell.height,
        .files           : ContainerFileCell.height,
        .header         : ContainerHeaderCell.height,
        .search         : ContainerSearchCell.height
        ]

    var isSectionRowEditable: [Section: Bool] = [
        .error          : false,
        .signatures     : true,
        .timestamp      : false,
        .files           : true,
        .header         : false,
        .search         : false
        ]

    var sectionHeaderTitle: [Section: String] = [
        .files           : L(LocKey.containerHeaderFilesTitle),
        .timestamp      : L(LocKey.containerHeaderTimestampTitle),
        .signatures     : L(LocKey.containerHeaderSignaturesTitle)
        ]

    private static let sectionsWithError: [Section] = [.header, .error, .files, .signatures]
    private static let sectionsDefault: [Section] = [.header, .files, .signatures]
    var sections: [Section] = ContainerViewController.sectionsDefault

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOnce()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let containerPath = containerPath else {
            return
        }
        
        showLoading(show: true)
        MoppLibContainerActions.sharedInstance().getContainerWithPath(containerPath, success: {(_ container: MoppLibContainer?) -> Void in
            guard let container = container else {
                return
            }
            self.container = container
            self.tableView.reloadData()
            self.showLoading(show: false)
        }, failure: { _ in
            self.showLoading(show: false)
        })
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
        guard let container = container else {
            return 0
        }
        
        switch sections[section] {
        case .error:
            return 1
        case .signatures:
            return container.signatures.count
        case .timestamp:
            return 1
        case .files:
            return container.dataFiles.count
        case .header:
            return 1
        case .search:
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
            return cell
        case .timestamp:
            let cell = tableView.dequeueReusableCell(withType: ContainerSignatureCell.self, for: indexPath)!
                //cell.populate(name: mockTimestamp[row], kind: .timestamp, colorTheme: .neutral, showBottomBorder: row < mockTimestamp.count - 1)
            return cell
        case .files:
            let cell = tableView.dequeueReusableCell(withType: ContainerFileCell.self, for: indexPath)!
                cell.populate(name: (container.dataFiles as! [MoppLibDataFile])[row].fileName, showBottomBorder: row < container.dataFiles.count - 1)
            return cell
        case .header:
            let cell = tableView.dequeueReusableCell(withType: ContainerHeaderCell.self, for: indexPath)!
                cell.populate(name: container.fileName)
            return cell
        case .search:
            let cell = tableView.dequeueReusableCell(withType: ContainerSearchCell.self, for: indexPath)!
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
        case .search:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return isSectionRowEditable[sections[indexPath.section]]!
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: L(LocKey.containerRowEditRemove)) { (action, indexPath) in
        }
        delete.backgroundColor = UIColor.moppWarning
        return [delete]
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section]
        if let title = sectionHeaderTitle[section] {
            if let header = MoppApp.instance.nibs[.containerElements]?.instantiate(withOwner: self, type: ContainerTableViewHeaderView.self) {
                header.delegate = self
                header.populate(withTitle: title, showAddButton: section == .files || section == .signatures, section: section)
                return header
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        let section = sections[_section]
        if sectionHeaderTitle[section] != nil {
            return ContainerTableViewHeaderView.height
        }
        return 0
    }
}

extension ContainerViewController {
    func setupOnce() {
        navigationItem.titleView = nil
        navigationItem.title = L(LocKey.containerTitle)
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

extension ContainerViewController : ContainerTableViewHeaderViewDelegate {
    func containerTableViewHeaderViewAddFiles(forSection section: ContainerViewController.Section) {
        
    }
}

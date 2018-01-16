//
//  SigningViewController.swift
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

class SigningViewController : MoppViewController {
    var requestCloseSearch: (() -> Void) = {}
    @IBOutlet weak var tableView: UITableView!

    enum Section {
        case containerFiles
        case containerFilesHeader
        case fileImport
    }

    var searchKeyword: String = String()
    var containerFiles: [String] = []
    var sections: [Section] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh()

        sections = [.fileImport, .containerFilesHeader, .containerFiles]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        LandingTabBarController.shared.presentButtons([.signTab, .cryptoTab, .myeIDTab])
        
        tableView.estimatedRowHeight = ContainerSignatureCell.height
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        closeSearch()
    }
    
    func refresh(searchKey: String? = nil) {
        var files = MoppFileManager.shared.documentsFiles()
        if let searchKey = searchKey {
            files = files.filter {
                let range = $0.range(of: searchKey, options: String.CompareOptions.caseInsensitive, range: nil, locale: nil)
                return range != nil
            }
        }
        containerFiles = files
        reloadContainerFilesSection()
    }
    
    func reloadContainerFilesSection() {
        if let containerSectionIndex = sections.index(where: { $0 == .containerFiles }) {
            tableView.reloadSections([containerSectionIndex], with: .none)
        }
    }
    
    func closeSearch() {
        searchKeyword = String()
        requestCloseSearch()
        containerFiles = MoppFileManager.shared.documentsFiles()
        tableView.reloadData()
    }
}

extension SigningViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section_: Int) -> Int {
        let section = sections[section_]
        switch section {
        case .containerFilesHeader:
            return 0
        case .containerFiles:
            return containerFiles.count
        case .fileImport:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        switch section {
            case .containerFiles:
                let cell = tableView.dequeueReusableCell(withType: SigningContainerCell.self, for: indexPath)!
                    cell.populate(filename: containerFiles[indexPath.row], searchKeyword: searchKeyword)
                return cell
            case .fileImport:
                return tableView.dequeueReusableCell(withType: SigningFileImportCell.self, for: indexPath)!
            case .containerFilesHeader:
                return UITableViewCell()
        }
    }
}

extension SigningViewController : UITableViewDelegate {    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section_: Int) -> UIView? {
        let section = sections[section_]
        if section == .containerFilesHeader {
            let headerView = MoppApp.instance.nibs[.signingElements]?.instantiate(withOwner: self, type: SigningTableViewHeaderView.self)
                headerView?.delegate = self
                headerView?.populate(title: L(.signingRecentContainers), &requestCloseSearch)
            return headerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        if section == .containerFiles {
            let filename = containerFiles[indexPath.row]
            let containerPath = MoppFileManager.shared.documentsDirectoryPath() + "/" + filename
            
            let containerViewController = UIStoryboard.container.instantiateInitialViewController() as! ContainerViewController
                containerViewController.containerPath = containerPath
            
            self.closeSearch()
            self.navigationController?.pushViewController(containerViewController, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section_: Int) -> CGFloat {
        let section = sections[section_]
        return section == .containerFilesHeader ? 50.0 : 0
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section = sections[indexPath.section]
        return section == .containerFiles
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let section = sections[indexPath.section]
        if section == .containerFiles {
            let delete = UITableViewRowAction(style: .destructive, title: L(LocKey.containerRowEditRemove)) { [weak self] action, indexPath in
                guard let strongSelf = self else { return }
                let filename = strongSelf.containerFiles[indexPath.row]
                MoppFileManager.shared.removeDocumentsFile(with: filename)
                strongSelf.containerFiles = MoppFileManager.shared.documentsFiles()
                tableView.reloadData()
            }
            delete.backgroundColor = UIColor.moppWarning
            return [delete]
        }
        return []
    }
}

extension SigningViewController: SigningTableViewHeaderViewDelegate {
    func signingTableViewHeaderViewSearchKeyChanged(_ searchKeyValue: String) {
        self.searchKeyword = searchKeyValue
        refresh(searchKey: searchKeyValue.isEmpty ? nil : searchKeyValue)
    }
    
    func signingTableViewHeaderViewDidEndSearch() {
        self.searchKeyword = String()
        containerFiles = MoppFileManager.shared.documentsFiles()
        tableView.reloadData()
    }
}

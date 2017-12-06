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
    @IBOutlet weak var beginLabel: UILabel!
    @IBOutlet weak var beginButton: UIButton!
    @IBOutlet weak var documentsTableView: UITableView!

    var containerFiles: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh()
        
        //beginLabel.text = L(LocKey.signatureViewBeginLabel)
        //beginButton.localizedTitle = LocKey.signatureViewBeginButton
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        requestCloseSearch()
    }
    
    func refresh(searchKey: String? = nil) {
        var files = MoppFileManager.shared.documentsFiles()
        if let searchKey = searchKey {
            files = files.filter {
                let range = $0.range(of: searchKey)
                return range != nil
            }
        }
        containerFiles = files
        documentsTableView.reloadData()
    }
}

extension SigningViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return containerFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withType: SigningContainerCell.self, for: indexPath)!
            cell.populate(filename: containerFiles[indexPath.row])
        return cell
    }
}

extension SigningViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SigningTableViewHeaderView.height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = MoppApp.instance.nibs[.signingElements]?.instantiate(withOwner: self, type: SigningTableViewHeaderView.self)
            headerView?.delegate = self
            headerView?.populate(title: L(.signingRecentContainers), &requestCloseSearch)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let filename = containerFiles[indexPath.row]
        let containerPath = MoppFileManager.shared.documentsDirectoryPath() + "/" + filename
        
        let containerViewController = UIStoryboard.container.instantiateInitialViewController() as! ContainerViewController
            containerViewController.containerPath = containerPath
        
        self.requestCloseSearch()
        self.navigationController?.pushViewController(containerViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
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
}

extension SigningViewController: SigningTableViewHeaderViewDelegate {
    func signingTableViewHeaderViewSearchKeyChanged(_ searchKeyValue: String) {
        refresh(searchKey: searchKeyValue.isEmpty ? nil : searchKeyValue)
    }
}

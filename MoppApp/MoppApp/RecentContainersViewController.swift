//
//  RecentContainersViewController.swift
//  MoppApp
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

import UIKit
class RecentContainersViewController : MoppModalViewController {
    var requestCloseSearch: (() -> Void) = {}
    @IBOutlet weak var tableView: UITableView!

    var accessibilityElementsList = [Any]()

    enum Section {
        case header
        case containerFiles
        case containerFilesHeaderViewPlaceholder
        case filesMissing
    }

    var searchKeyword: String = String()
    var sections: [Section] = []

    var containerFiles: [String] = [] {
        didSet {
            let currentSectionsCount = sections.count
            if containerFiles.isEmpty {
                sections = [.header, .containerFilesHeaderViewPlaceholder, .containerFiles, .filesMissing]
            } else {
                sections = [.header, .containerFilesHeaderViewPlaceholder, .containerFiles]
            }
            if currentSectionsCount != sections.count {
                tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInsetAdjustmentBehavior = .never
        refresh()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.estimatedRowHeight = ContainerSignatureCell.height
        tableView.rowHeight = UITableView.automaticDimension
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        closeSearch()

        if UIAccessibility.isVoiceOverRunning {
            for cell in tableView.visibleCells {
                if cell is RecentContainersHeaderCell {
                    self.accessibilityElementsList.insert(cell, at: 0)
                } else if cell is RecentContainersNameCell {
                    self.accessibilityElementsList.append(cell)
                }
                
                self.accessibilityElements = accessibilityElementsList
            }
        }
    }

    func refresh(searchKey: String? = nil) {
        var filesFound = MoppFileManager.shared.documentsFiles()
        if let searchKey = searchKey {
            filesFound = filesFound.filter {
                let range = $0.range(of: searchKey, options: String.CompareOptions.caseInsensitive, range: nil, locale: nil)
                return range != nil
            }
        }
        filesFound = filterContainerFiles(containerFiles: filesFound)
        containerFiles = filesFound
        reloadContainerFilesSection()
    }

    func reloadContainerFilesSection() {
        if let containerSectionIndex = sections.firstIndex(where: { $0 == .containerFiles }) {
            tableView.reloadSections([containerSectionIndex], with: .none)
        }
    }

    func closeSearch() {
        searchKeyword = String()
        requestCloseSearch()
        containerFiles = filterContainerFiles(containerFiles: MoppFileManager.shared.documentsFiles())
        tableView.reloadData()
    }
    
    func filterContainerFiles(containerFiles: [String]?) -> [String] {
        var filteredContainerFiles = [String]()
        if let files = containerFiles, files.count > 0 {
            filteredContainerFiles = files.filter { fileName in
                let fileURL = URL(fileURLWithPath: fileName)
                let pathExtension = fileURL.pathExtension
                if !pathExtension.isEmpty {
                    return pathExtension.isAsicContainerExtension || pathExtension.isCdocContainerExtension || pathExtension.isPdfContainerExtension
                }
                
                return false
            }
        }
        
        return filteredContainerFiles
    }
}

extension RecentContainersViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section_: Int) -> Int {
        let section = sections[section_]
        switch section {
        case .header, .filesMissing:
            return 1
        case .containerFilesHeaderViewPlaceholder:
            return 0
        case .containerFiles:
            return containerFiles.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        switch section {
            case .header:
                let cell = tableView.dequeueReusableCell(withType: RecentContainersHeaderCell.self, for: indexPath)!
                    cell.delegate = self
                return cell
            case .containerFiles:
                let cell = tableView.dequeueReusableCell(withType: RecentContainersNameCell.self, for: indexPath)!
            cell.populate(filename: containerFiles[indexPath.row], searchKeyword: searchKeyword, showSeparator: indexPath.row < containerFiles.count - 1, row: indexPath.row)
                return cell
            case .filesMissing:
                let cell = tableView.dequeueReusableCell(withType: RecentContainersEmptyListCell.self, for: indexPath)!
                    cell.populate(emptySearch: !searchKeyword.isEmpty)
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: L(.recentContainersEmptySearchMessage))
                return cell
            case .containerFilesHeaderViewPlaceholder:
                return UITableViewCell()
        }
    }
}

extension RecentContainersViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section_: Int) -> UIView? {
        let section = sections[section_]
        if section == .containerFilesHeaderViewPlaceholder {
            let headerView = MoppApp.instance.nibs[.recentContainersElements]?.instantiate(withOwner: self, type: SigningTableViewHeaderView.self)
                headerView?.delegate = self
                headerView?.populate(title: L(.signingRecentContainers), &requestCloseSearch)
            guard let tableHeaderView = headerView, let tableSearchField = tableHeaderView.searchTextField else { return UIView() }
            self.accessibilityElementsList.append(contentsOf: [tableHeaderView, tableSearchField])
            return headerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        if section == .containerFiles {
            let filename = containerFiles[indexPath.row]
            let containerPath = MoppFileManager.shared.documentsDirectoryPath() + "/" + filename

            self.closeSearch()
            dismiss(animated: true, completion: {
                let ext = (filename as NSString).pathExtension
                var navController: UINavigationController = (LandingViewController.shared.viewController(for: .signTab) as? UINavigationController)!

                let failure: (() -> Void) = {
                    LandingViewController.shared.importProgressViewController.dismissRecursivelyIfPresented(animated: false, completion: nil)
                    let alert = UIAlertController(title: L(.fileImportOpenExistingFailedAlertTitle), message: L(.fileImportOpenExistingFailedAlertMessage, [filename]), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))

                    navController.viewControllers.last!.present(alert, animated: true)
                }

                if ext.isAsicContainerExtension || ext.isPdfContainerExtension {
                    let containerPathURL = URL(fileURLWithPath: containerPath)
                    if SiVaUtil.isDocumentSentToSiVa(fileUrl: containerPathURL) || (containerPathURL.pathExtension == "asics" || containerPathURL.pathExtension == "scs") {
                        SiVaUtil.displaySendingToSiVaDialog { hasAgreed in
                            if (containerPathURL.pathExtension == "ddoc" || containerPathURL.pathExtension == "pdf") && !hasAgreed {
                                return
                            }
                            self.openContainer(containerPath: containerPath, navController: navController, isSendingToSivaAgreed: hasAgreed)
                        }
                    } else {
                        self.openContainer(containerPath: containerPath, navController: navController, isSendingToSivaAgreed: true)
                    }
                } else {
                    var containerViewController: ContainerViewController
                    LandingViewController.shared.containerType = .cdoc
                    containerViewController = CryptoContainerViewController.instantiate()
                    containerViewController.containerPath = containerPath
                    let filePath = containerPath as NSString
                    let container = CryptoContainer(filename: filePath.lastPathComponent as NSString, filePath: filePath)

                    MoppLibCryptoActions.sharedInstance().parseCdocInfo(
                        filePath as String?,
                        success: {(_ cdocInfo: CdocInfo?) -> Void in
                            guard let strongCdocInfo = cdocInfo else { return }
                            let cryptoContainer = (containerViewController as! CryptoContainerViewController)
                            container.addressees = strongCdocInfo.addressees as? [Addressee] ?? []
                            container.dataFiles = strongCdocInfo.dataFiles
                            cryptoContainer.containerPath = filePath as String?
                            cryptoContainer.state = .opened

                            cryptoContainer.container = container
                            cryptoContainer.isContainerEncrypted = true

                            navController = (LandingViewController.shared.viewController(for: .cryptoTab) as? UINavigationController)!
                            navController.pushViewController(cryptoContainer, animated: true)
                    },
                        failure: { _ in
                            failure()
                        }
                    )
                }

            })
        }
    }

    func openContainer(containerPath: String, navController: UINavigationController, isSendingToSivaAgreed: Bool) {
        var containerViewController: ContainerViewController
        LandingViewController.shared.containerType = .asic
        containerViewController = SigningContainerViewController.instantiate()
        containerViewController.containerPath = containerPath
        containerViewController.isSendingToSivaAgreed = isSendingToSivaAgreed
        navController.pushViewController(containerViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section_: Int) -> CGFloat {
        let section = sections[section_]
        return section == .containerFilesHeaderViewPlaceholder ? 50.0 : 0
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section = sections[indexPath.section]
        return section == .containerFiles
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.isEmpty {
            return UISwipeActionsConfiguration()
        }
        let section = sections[indexPath.section]
        if section == .containerFiles {
            let delete = UIContextualAction(style: .destructive, title: L(LocKey.containerRowEditRemove)) { [weak self] action, view, boolValue in
                guard let strongSelf = self else { return }
                let filename = strongSelf.containerFiles[indexPath.row]
                MoppFileManager.shared.removeDocumentsFile(with: filename)
                strongSelf.containerFiles = strongSelf.filterContainerFiles(containerFiles: MoppFileManager.shared.documentsFiles())
                UIAccessibility.post(notification: .screenChanged, argument: L(.recentDocumentRemoved))
                tableView.reloadData()
            }
            delete.backgroundColor = UIColor.moppError
            return UISwipeActionsConfiguration(actions: [delete])
        }
        return UISwipeActionsConfiguration()
    }
}

extension RecentContainersViewController: SigningTableViewHeaderViewDelegate {
    func signingTableViewHeaderViewSearchKeyChanged(_ searchKeyValue: String) {
        self.searchKeyword = searchKeyValue
        refresh(searchKey: searchKeyValue.isEmpty ? nil : searchKeyValue)
    }

    func signingTableViewHeaderViewDidEndSearch() {
        self.searchKeyword = String()
        containerFiles = filterContainerFiles(containerFiles: MoppFileManager.shared.documentsFiles())
        tableView.reloadData()
    }
}

extension RecentContainersViewController : SigningFileImportCellDelegate {
    func signingFileImportDidTapAddFiles() {
        NotificationCenter.default.post(
            name: .startImportingFilesWithDocumentPickerNotificationName,
            object: nil,
            userInfo: [kKeyFileImportIntent: MoppApp.FileImportIntent.openOrCreate, kKeyContainerType: MoppApp.ContainerType.asic])
    }
}

extension RecentContainersViewController : RecentContainersHeaderDelegate {
    func recentContainersHeaderDismiss() {
        dismiss(animated: true, completion: nil)
    }
}

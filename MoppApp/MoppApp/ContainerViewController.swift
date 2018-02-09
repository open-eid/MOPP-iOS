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
class ContainerViewController : MoppViewController {
    var container: MoppLibContainer!
    var containerPath: String!
    var isForPreview: Bool = false
    var isCreated: Bool = false
    var forcePDFContentPreview: Bool = false
    
    @IBOutlet weak var tableView: UITableView!

    enum Section {
        case notifications
        case signatures
        case missingSignatures
        case timestamp
        case dataFiles
        case importDataFiles
        case header
        case search
    }

    enum ContainerState {
        case loading        // Before container is opened or created
        case created
        case opened
        case preview
    }
    
    var isSectionRowEditable: [Section: Bool] = [
        .notifications   : false,
        .signatures     : true,
        .timestamp      : false,
        .dataFiles      : true,
        .header         : false,
        .search         : false
        ]

    var sectionHeaderTitle: [Section: String] = [
        .dataFiles      : L(LocKey.containerHeaderFilesTitle),
        .timestamp      : L(LocKey.containerHeaderTimestampTitle),
        .signatures     : L(LocKey.containerHeaderSignaturesTitle)
        ]

    private static let sectionsDefault  : [Section] = [.notifications, .header, .dataFiles, .signatures]
    private static let sectionsNoSignatures : [Section] = [.notifications, .header, .dataFiles, .importDataFiles]
    
    var sections: [Section] = ContainerViewController.sectionsDefault
    var notifications: [(isSuccess: Bool, text: String)] = []
    var state: ContainerState!
    
    private var invalidSignaturesCount: Int {
        if container == nil { return 0 }
        return (container.signatures as! [MoppLibSignature]).filter { !$0.isValid }.count
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInsetAdjustmentBehavior = .never
        
        updateState(.loading)
        LandingViewController.shared.tabButtonsDelegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(signatureCreatedFinished), name: .signatureCreatedFinishedNotificationName, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func signatureCreatedFinished() {
        DispatchQueue.main.async {
        [weak self] in
            self?.isCreated = false
            self?.isForPreview = false
            self?.state = .loading
            self?.showLoading(show: true)
            self?.openContainer(afterSignatureCreated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadData()
        updateState(state)
    
        tableView.estimatedRowHeight = ContainerSignatureCell.height
        tableView.rowHeight = UITableViewAutomaticDimension
        
        showLoading(show: state == .loading)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        openContainer()
    }
    
    func updateState(_ newState: ContainerState) {
        switch newState {
            case .loading:
                setupNavigationItemForPushedViewController(title: L(.containerValidating))
            
            case .created:
                LandingViewController.shared.presentButtons(isForPreview ? [] : [.signButton])
                setupNavigationItemForPushedViewController(title: L(.containerSignTitle))
            
            case .opened:
                var tabButtons: [LandingViewController.TabButtonId] = []
                if !isForPreview {
                    tabButtons = [.shareButton, .signButton]
                }
                LandingViewController.shared.presentButtons(tabButtons)
                setupNavigationItemForPushedViewController(title: L(.containerValidateTitle))
            
            case .preview:
                let containerUrl = URL(fileURLWithPath: containerPath!)
                let (filename, ext) = containerUrl.lastPathComponent.filenameComponents()
                setupNavigationItemForPushedViewController(title: filename + "." + ext)
            
        }
        state = newState
    }
    
    func openContainer(afterSignatureCreated: Bool = false) {
        if state != .loading { return }
        let isPDF = containerPath.filenameComponents().ext.lowercased() == ContainerFormatPDF
        forcePDFContentPreview = isPDF
        MoppLibContainerActions.sharedInstance().getContainerWithPath(containerPath, success: { [weak self] container in
            guard let container = container else {
                return
            }
            
            guard let strongSelf = self else { return }
            
            strongSelf.notifications = []
            
            if afterSignatureCreated {
                strongSelf.notifications.append((true, L(.containerDetailsSigningSuccess)))
            }
            
            let invalidSignaturesCount = (container.signatures as! [MoppLibSignature]).filter { !$0.isValid }.count
            if invalidSignaturesCount > 0 {
                var signatureWarningText: String!
                if invalidSignaturesCount == 1 {
                    signatureWarningText = L(.containerErrorMessageInvalidSignature)
                } else if invalidSignaturesCount > 1 {
                    signatureWarningText = L(.containerErrorMessageInvalidSignatures, [invalidSignaturesCount])
                }
                strongSelf.notifications.append((false, signatureWarningText))
            }

            strongSelf.sections = ContainerViewController.sectionsDefault
            
            strongSelf.container = container
            strongSelf.reloadData()
            strongSelf.showLoading(show: false)
            
        }, failure: { [weak self] error in

            let nserror = error! as NSError
            var message = nserror.domain
            var title: String? = nil
            if (nserror.code == moppLibErrorGeneral.rawValue) {
                title = L(.fileImportOpenExistingFailedAlertTitle)
                message = L(.fileImportOpenExistingFailedAlertMessage, [self?.containerPath.substr(fromLast: "/") ?? String()])
            }
            self?.errorAlert(message: message, title: title, dismissCallback: { _ in
                _ = self?.navigationController?.popViewController(animated: true)
            });
        })
    }
    
    override func showLoading(show: Bool, forFrame: CGRect? = nil) {
        super.showLoading(show: show, forFrame: tableView.frame)
        tableView.isHidden = show
    }
    
    override func willEnterForeground() {
        refreshLoadingAnimation()
    }

    func startSigningWithMobileID() {
        let mobileIdEditViewController = UIStoryboard.landing.instantiateViewController(with: MobileIDEditViewController.self)
            mobileIdEditViewController.modalPresentationStyle = .overFullScreen
            mobileIdEditViewController.delegate = self
        present(mobileIdEditViewController, animated: false, completion: nil)
    }
    
    class func instantiate() -> ContainerViewController {
        return UIStoryboard.container.instantiateInitialViewController(of: ContainerViewController.self)
    }
    
    func reloadContainer() {
        state = .loading
        showLoading(show: true)
        openContainer()
        reloadData()
    }
}

extension ContainerViewController : LandingViewControllerTabButtonsDelegate {
    func landingViewControllerTabButtonTapped(tabButtonId: LandingViewController.TabButtonId) {
        if tabButtonId == .signButton {
            startSigningWithMobileID()
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
        case .notifications:
            return notifications.count
        case .signatures:
            return container.signatures.count
        case .dataFiles:
            return container.dataFiles.count
        case .missingSignatures, .header, .search, .timestamp, .importDataFiles:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        switch sections[indexPath.section] {
        case .notifications:
            let cell = tableView.dequeueReusableCell(withType: ContainerNotificationCell.self, for: indexPath)!
                cell.populate(isSuccess: notifications[indexPath.row].isSuccess, text: notifications[indexPath.row].text)
            return cell
        case .signatures:
            let cell = tableView.dequeueReusableCell(withType: ContainerSignatureCell.self, for: indexPath)!
                cell.delegate = self
            let signature = container.signatures[row] as! MoppLibSignature
            cell.populate(
                with: signature,
                kind: .signature,
                showBottomBorder: row < container.signatures.count - 1,
                showRemoveButton: !isForPreview && !container.isLegacyType(),
                signatureIndex: row)
            return cell
        case .missingSignatures:
            let cell = tableView.dequeueReusableCell(withType: ContainerNoSignaturesCell.self, for: indexPath)!
            return cell
        case .timestamp:
            let cell = tableView.dequeueReusableCell(withType: ContainerSignatureCell.self, for: indexPath)!
                //cell.populate(name: mockTimestamp[row], kind: .timestamp, colorTheme: .neutral, showBottomBorder: row < mockTimestamp.count - 1)
            return cell
        case .dataFiles:
            let cell = tableView.dequeueReusableCell(withType: ContainerFileCell.self, for: indexPath)!
                cell.delegate = self
                cell.populate(
                    name: (container.dataFiles as! [MoppLibDataFile])[row].fileName,
                    showBottomBorder: row < container.dataFiles.count - 1,
                    showRemoveButton:
                        container.dataFiles.count > 1   &&
                        !isForPreview                   &&
                        container.signatures.isEmpty    &&
                        !container.isLegacyType(),
                    dataFileIndex: row)
            return cell
        case .importDataFiles:
            let cell = tableView.dequeueReusableCell(withType: ContainerImportFilesCell.self, for: indexPath)!
                cell.delegate = self
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

extension ContainerViewController : ContainerSignatureDelegate {
    func containerSignatureRemove(signatureIndex: Int) {
            guard let signature = container.signatures[signatureIndex] as? MoppLibSignature else {
                return
            }
            confirmDeleteAlert(
                message: L(.signatureRemoveConfirmMessage),
                confirmCallback: { [weak self] (alertAction) in
                
                self?.notifications = []
                self?.showLoading(show: true)
                MoppLibContainerActions.sharedInstance().remove(
                    signature,
                    fromContainerWithPath: self?.container.filePath,
                    success: { [weak self] container in
                        self?.showLoading(show: false)
                        self?.container.signatures.remove(at: signatureIndex)
                        self?.reloadData()
                    },
                    failure: { [weak self] error in
                        self?.showLoading(show: false)
                        self?.reloadData()
                        self?.errorAlert(message: error?.localizedDescription)
                    })
            })
    }
}

extension ContainerViewController : ContainerFileDelegate {
    func removeDataFile(dataFileIndex: Int) {    
        confirmDeleteAlert(
            message: L(.datafileRemoveConfirmMessage),
            confirmCallback: { [weak self] (alertAction) in
            
            self?.notifications = []
            self?.showLoading(show: true)
            MoppLibContainerActions.sharedInstance().removeDataFileFromContainer(
                withPath: self?.containerPath,
                at: UInt(dataFileIndex),
                success: { [weak self] container in
                    self?.showLoading(show: false)
                    self?.container.dataFiles.remove(at: dataFileIndex)
                    self?.reloadData()
                },
                failure: { [weak self] error in
                    self?.showLoading(show: false)
                    self?.reloadData()
                    self?.errorAlert(message: error?.localizedDescription)
                })
        })
    }
}

extension ContainerViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .notifications:
            break
        case .signatures:
            break
        case .missingSignatures:
            break
        case .timestamp:
            break;
        case .dataFiles:
            
            // Open preview of data file
            
            let dataFile = container.dataFiles[indexPath.row] as! MoppLibDataFile
            let destinationPath = MoppFileManager.shared.tempFilePath(withFileName: dataFile.fileName)
    
            let openContainerPreview: (_ isPDF: Bool) -> Void = { [weak self] isPDF in
                let containerViewController = ContainerViewController.instantiate()
                    containerViewController.containerPath = destinationPath
                    containerViewController.isForPreview = true
                    containerViewController.forcePDFContentPreview = isPDF
                self?.navigationController?.pushViewController(containerViewController, animated: true)
            }
    
            let openContentPreview: (_ filePath: String) -> Void = { [weak self] filePath in
                let dataFilePreviewViewController = UIStoryboard.container.instantiateViewController(with: DataFilePreviewViewController.self)
                    dataFilePreviewViewController.previewFilePath = filePath
                self?.navigationController?.pushViewController(dataFilePreviewViewController, animated: true)
            }
    
            let openPDFPreview: () -> Void = { [weak self] in
                self?.showLoading(show: true)
                self?.updateState(.loading)
                MoppLibContainerActions.sharedInstance().getContainerWithPath(destinationPath,
                    success: { [weak self] (_ container: MoppLibContainer?) -> Void in
                        self?.showLoading(show: false)
                        self?.updateState(.opened)
                        if container == nil {
                            return
                        }
                    
                        let signatureCount = container?.signatures.count ?? 0
                        if signatureCount > 0 && !(self?.forcePDFContentPreview ?? false) {
                            openContainerPreview(true)
                        } else {
                            openContentPreview(destinationPath)
                        }
                    },
                    failure: { [weak self] error in
                        self?.errorAlert(message: error?.localizedDescription)
                    })
            }
    
            // If current container is PDF opened as a container preview then open it as a content preview which
            // is same as opening it's data file (which is a reference to itself) as a content preview
            if forcePDFContentPreview {
                openContentPreview(containerPath)
            } else {
                MoppLibContainerActions.sharedInstance().container(
                    container.filePath,
                    saveDataFile: dataFile.fileName,
                    to: destinationPath,
                    success: { [weak self] in
                        self?.notifications = []
                        self?.tableView.reloadData()
                        let (_, dataFileExt) = dataFile.fileName.filenameComponents()
                        let isPDF = dataFileExt.lowercased() == ContainerFormatPDF
                        let forcePDFContentPreview = self?.forcePDFContentPreview ?? false
                        
                        if dataFileExt.isContainerExtension || (isPDF && !forcePDFContentPreview) {
                        
                            // If container is PDF check signatures count with showing loading
                            if isPDF {
                                openPDFPreview()
                            } else {
                                openContainerPreview(isPDF)
                            }
                        } else {
                            openContentPreview(destinationPath)
                        }
                        
                    }, failure: { [weak self] error in
                        self?.errorAlert(message: error?.localizedDescription)
                    })
            }
            break
        case .header:
            break
        case .search:
            break
        case .importDataFiles:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section]
        var title: String!
        switch section {
            case .dataFiles:
                title = isCreated ? L(LocKey.containerHeaderCreateFilesTitle) : L(LocKey.containerHeaderFilesTitle)
            default:
                title = sectionHeaderTitle[section]
        }

        if let header = MoppApp.instance.nibs[.containerElements]?.instantiate(withOwner: self, type: ContainerTableViewHeaderView.self) {
            let signaturesCount = container?.signatures?.count ?? 0
            let isContainerLegacyType = container?.isLegacyType() ?? true
            header.delegate = self
            header.populate(
                withTitle: title,
                section: section,
                showAddButton:
                    section == .dataFiles   &&
                    !isCreated              &&
                    signaturesCount == 0    &&
                    !isForPreview           &&
                    !isContainerLegacyType)
            return header
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
    
    func reloadData() {
        guard let container = container else {
            return
        }

        if isForPreview {
            updateState(.preview)
        }
        else if container.signatures.isEmpty && isCreated {
            updateState(.created)
        }
        else {
            updateState(.opened)
        }

        if container.signatures.isEmpty {
            sections = (isForPreview || !isCreated) ? ContainerViewController.sectionsDefault : ContainerViewController.sectionsNoSignatures
            if let signaturesIndex = sections.index(where: { $0 == .signatures }) {
                if !sections.contains(.missingSignatures) {
                    sections.insert(.missingSignatures, at: signaturesIndex + 1)
                }
            }
        } else {
            sections = ContainerViewController.sectionsDefault
        }
        
        tableView.reloadData()
        
        // Animate away success message if there is any
        if let notificationIndex = notifications.index(where: { $0.0 == true }), sections.contains(.notifications) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.notifications.remove(at: notificationIndex)
                if let notificationsSection = self?.sections.index(where: { $0 == .notifications }) {
                    self?.tableView.reloadSections([notificationsSection], with: .automatic)
                }
            }
        }
        
    }
}

extension ContainerViewController : MobileIDEditViewControllerDelegate {   
    func mobileIDEditViewControllerDidDismiss(cancelled: Bool, phoneNumber: String?, idCode: String?) {
        if cancelled { return }
        
        guard let phoneNumber = phoneNumber else { return }
        guard let idCode = idCode else { return }
        
        let mobileIDChallengeview = UIStoryboard.landing.instantiateViewController(with: MobileIDChallengeViewController.self)
            mobileIDChallengeview.modalPresentationStyle = .overFullScreen
        present(mobileIDChallengeview, animated: false)

        Session.shared.createMobileSignature(
            withContainer: container.filePath,
            idCode: idCode,
            language: decideLanguageBasedOnPreferredLanguages(),
            phoneNumber: phoneNumber)
    }
    
    func decideLanguageBasedOnPreferredLanguages() -> String {
        var language: String = String()
        let prefLanguages = NSLocale.preferredLanguages
        for i in 0..<prefLanguages.count {
            if prefLanguages[i].hasPrefix("et-") {
                language = "EST"
                break
            }
            else if prefLanguages[i].hasPrefix("lt-") {
                language = "LIT"
                break
            }
            else if prefLanguages[i].hasPrefix("ru-") {
                language = "RUS"
                break
            }
        }
        if language.isEmpty {
            language = "ENG"
        }
        
        return language
    }
}

extension ContainerViewController : ContainerTableViewHeaderDelegate {
    func didTapContainerHeaderButton() {
        NotificationCenter.default.post(
            name: .startImportingFilesWithDocumentPickerNotificationName,
            object: nil,
            userInfo: [kKeyFileImportIntent: MoppApp.FileImportIntent.addToContainer])
    }
}

extension ContainerViewController : ContainerImportCellDelegate {
    func containerImportCellAddFiles() {
        NotificationCenter.default.post(
            name: .startImportingFilesWithDocumentPickerNotificationName,
            object: nil,
            userInfo: [kKeyFileImportIntent: MoppApp.FileImportIntent.addToContainer])
    }
}

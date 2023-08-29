//
//  ContainerViewController.swift
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

import Foundation
import MoppLib

protocol ContainerViewControllerDelegate: AnyObject {
    func getDataFileCount() -> Int
    func getContainerPath() -> String
    func getContainer() -> MoppLibContainer
    func openContainer(afterSignatureCreated: Bool)
    func getContainerFilename() -> String
    func getDataFileRelativePath(index: Int) -> String
    func getDataFileDisplayName(index: Int) -> String?
    func isContainerEmpty() -> Bool
    func removeDataFile(index: Int)
    func saveDataFile(name: String?, containerPath: String?)
}

protocol SigningContainerViewControllerDelegate: AnyObject {
    func startSigning()
    func getSignaturesCount() -> Int
    func getTimestampTokensCount() -> Int
    func getSignature(index: Int) -> Any
    func getTimestampToken(index: Int) -> Any
    func removeSignature(index: Int)
    func isContainerSignable() -> Bool
}

protocol CryptoContainerViewControllerDelegate: AnyObject {
    func addAddressees()
    func getAddressee(index: Int) -> Any
    func getAddresseeCount() -> Int
    func removeSelectedAddressee(index: Int)
    func getContainer() -> CryptoContainer
    func startEncrypting()
    func startDecrypting()
}

class ContainerViewController : MoppViewController, ContainerActions, PreviewActions, ContainerFileUpdatedDelegate {

    weak var containerViewDelegate: ContainerViewControllerDelegate!
    weak var cryptoContainerViewDelegate: CryptoContainerViewControllerDelegate!
    weak var signingContainerViewDelegate: SigningContainerViewControllerDelegate!
    var containerModel: Any!

    var containerPath: String!
    var isForPreview: Bool = false
    var isCreated: Bool = false
    var forcePDFContentPreview: Bool = false
    var startSigningWhenOpened = false
    var isEncrypted = false
    var isDecrypted = false
    let landingViewController = LandingViewController.shared!
    var isAsicContainer = LandingViewController.shared.containerType == .asic
    var isEmptyFileWarningSet = false

    var asicsSignatures = [MoppLibSignature]()
    var asicsDataFiles = [MoppLibDataFile]()
    var asicsNestedContainerPath = ""
    var isAsicsInitialLoadingDone = false
    var isLoadingNestedAsicsDone = false
    var isSendingToSivaAgreed = true
    
    private static let unnamedDataFile = "datafile"
    
    private var isFileSaveableCache: [IndexPath: Bool] = [:]
    private var isDatafileReloaded = false

    @IBOutlet weak var tableView: UITableView!

    var isSignaturesEmpty: Bool {
        if !isAsicContainer { return true }
        return asicsSignatures.count == 0 && signingContainerViewDelegate.getSignaturesCount() == 0
    }

    enum Section {
        case notifications
        case signatures
        case containerTimestamps
        case missingSignatures
        case timestamp
        case dataFiles
        case importDataFiles
        case addressees
        case importAddressees
        case missingAddressees
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
        .addressees     : true,
        .missingAddressees : false,
        .header         : false,
        .search         : false
        ]

    var sectionHeaderTitle: [Section: String] = [
        .dataFiles      : L(LocKey.containerHeaderFilesTitle),
        .timestamp      : L(LocKey.containerHeaderTimestampTitle),
        .missingAddressees  : L(LocKey.containerHeaderCreateAddresseesTitle),
        .addressees  : L(LocKey.containerHeaderCreateAddresseesTitle),
        .signatures     : L(LocKey.containerHeaderSignaturesTitle),
        .containerTimestamps : L(LocKey.containerHeaderTimestampsTitle)
        ]

    internal static let sectionsDefault  : [Section] = [.notifications, .header, .dataFiles, .signatures]
    private static let sectionsNoSignatures : [Section] = [.notifications, .header, .dataFiles, .importDataFiles]
    internal static let sectionsNoAddresses : [Section] =  [.notifications, .header, .dataFiles, .importDataFiles, .missingAddressees, .importAddressees]
    internal static let sectionsWithAddresses : [Section] = [.notifications, .header, .dataFiles, .importDataFiles, .addressees, .importAddressees]
    internal static let sectionsEncrypted : [Section] = [.notifications, .header, .dataFiles, .addressees]
    internal static let sectionsWithTimestampNoSignatures : [Section] = [.notifications, .header, .dataFiles, .containerTimestamps]
    internal static let sectionsWithTimestamp : [Section] = [.notifications, .header, .dataFiles, .containerTimestamps, .signatures]
    var sections: [Section] = ContainerViewController.sectionsDefault
    var notifications: [NotificationMessage] = []
    var state: ContainerState!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInsetAdjustmentBehavior = .never
        updateState(.loading)

        NotificationCenter.default.addObserver(self, selector: #selector(signatureCreatedFinished), name: .signatureCreatedFinishedNotificationName, object: nil)

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self]_ in
            self?.refreshLoadingAnimation()
        }
        
        guard let leftBarUIButton = self.navigationItem.leftBarButtonItem, let bottomUIButtons = LandingViewController.shared.buttonsStackView, let tableUIView = tableView else {
            printLog("Unable to get leftBarButtonItem, LandingViewController buttonsStackView or tableView")
            return
        }
        
        UIAccessibility.post(notification: .screenChanged, argument: tableUIView)
        
        self.accessibilityElements = [leftBarUIButton, tableUIView, bottomUIButtons, leftBarUIButton]
    }

    deinit {
        isDatafileReloaded = false
        clearIsSaveableCache()
        NotificationCenter.default.removeObserver(self)
    }

    @objc func signatureCreatedFinished() {
        DispatchQueue.main.async {
        [weak self] in
            self?.isCreated = false
            self?.isForPreview = false
            self?.updateState(.loading)
            self?.containerViewDelegate.openContainer(afterSignatureCreated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        landingViewController.tabButtonsDelegate = self

        reloadData()
        updateState(state)

        tableView.estimatedRowHeight = ContainerSignatureCell.height
        tableView.rowHeight = UITableView.automaticDimension

        showLoading(show: state == .loading)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        containerViewDelegate.openContainer(afterSignatureCreated:false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        isDatafileReloaded = false
        clearIsSaveableCache()
        isEmptyFileWarningSet = false
    }

    func updateState(_ newState: ContainerState) {
        showLoading(show: newState == .loading)
        switch newState {
            case .loading:
                if isForPreview {
                    LandingViewController.shared.presentButtons([])
                }
                setupNavigationItemForPushedViewController(title: L(.containerValidating))

            case .created:
                if isAsicContainer {
                    setupNavigationItemForPushedViewController(title: L(.containerSignTitle))
                    LandingViewController.shared.presentButtons(isForPreview ? [] : [.signButton])
                }else{
                    setupNavigationItemForPushedViewController(title: L(.containerEncryptionTitle))
                    LandingViewController.shared.presentButtons(isForPreview ? [] : [.encryptButton])
                }

            case .opened:
                var tabButtons: [LandingViewController.TabButtonId] = []

                let asicContainer = self.containerViewDelegate?.getContainer()
                checkEmptyFilesInContainer(asicContainer: asicContainer)

                if !isForPreview && isAsicContainer {
                    if isDdocOrAsicsContainer(containerPath: containerPath) || isEmptyFileWarningSet {
                        checkIfDdocParentContainerIsTimestamped()
                        tabButtons = [.shareButton]
                        setupNavigationItemForPushedViewController(title: L(.containerValidateTitle))
                    } else {
                        tabButtons = [.shareButton, .signButton]
                        setupNavigationItemForPushedViewController(title: L(.containerValidateTitle))
                    }
                }
                else if !isForPreview {
                    if isDecrypted {
                        tabButtons = []
                    } else {
                        tabButtons = [.shareButton, .decryptButton]
                    }
                    setupNavigationItemForPushedViewController(title: L(.containerDecryptionTitle))
                } else {
                    setupNavigationItemForPushedViewController(title: L(.containerValidateTitle))
                    tabButtons = [.shareButton]
                }
                LandingViewController.shared.presentButtons(tabButtons)

            case .preview:
                let containerUrl = URL(fileURLWithPath: containerPath!)
                let (filename, ext) = containerUrl.lastPathComponent.filenameComponents()
                LandingViewController.shared.presentButtons([])
                setupNavigationItemForPushedViewController(title: filename + "." + ext)
        }
        state = newState
    }

    override func showLoading(show: Bool, forFrame: CGRect? = nil) {
        super.showLoading(show: show, forFrame: tableView.frame)
        tableView.isHidden = show
    }

    class func instantiate() -> ContainerViewController {
        return UIStoryboard.container.instantiateInitialViewController(of: ContainerViewController.self)
    }

    func reloadContainer() {
        updateState(.loading)
        containerViewDelegate.openContainer(afterSignatureCreated:false)
        reloadData()
    }
    
    func didUpdateDownloadButton(index: Int) {
        if let sectionIndex = sections.firstIndex(where: { $0 == .dataFiles }) {
            tableView.reloadRows(at: [IndexPath(row: index, section: sectionIndex)], with: .automatic)
        } else {
            tableView.reloadData()
        }
    }

    func isDdocOrAsicsContainer(containerPath: String) -> Bool {
        let fileLocation: URL = URL(fileURLWithPath: containerPath)

        let forbiddenMimetypes: [String] = [ContainerFormatDdocMimetype, ContainerFormatAsicsMimetype]

        if isAsicsContainer() || isDdocContainer() {
            return true
        }

        let mimeType: String = MimeTypeExtractor.getMimeTypeFromContainer(filePath: fileLocation)

        if forbiddenMimetypes.contains(mimeType) {
            return true
        }

        return false
    }

    func isAsicsContainer() -> Bool {
        let fileLocation: URL = URL(fileURLWithPath: containerPath)
        return fileLocation.pathExtension == ContainerFormatAsics || fileLocation.pathExtension == ContainerFormatAsicsShort
    }

    func isDdocContainer() -> Bool {
        let fileLocation: URL = URL(fileURLWithPath: containerPath)
        return fileLocation.pathExtension == ContainerFormatDdoc
    }

    private func checkEmptyFilesInContainer(asicContainer: MoppLibContainer?) {
        if let dataFiles = asicContainer?.dataFiles, !isEmptyFileWarningSet {
            var isEmptyFileInContainer = false
            for dataFile in dataFiles {
                guard let dataFile = dataFile as? MoppLibDataFile,
                      dataFile.fileSize == 0 else { continue }
                isEmptyFileInContainer = true
                break
            }
            if isEmptyFileInContainer {
                self.notifications.append(NotificationMessage(isSuccess: false, text: L(.fileImportFailedEmptyFileImported)))
                isEmptyFileWarningSet = true
            }
        }
    }

    func setSections() {
        if isSignaturesEmpty && isAsicContainer {
            sections = (isForPreview || !isCreated) ? ContainerViewController.sectionsDefault : ContainerViewController.sectionsNoSignatures
            if let signaturesIndex = sections.firstIndex(where: { $0 == .signatures }) {
                if !sections.contains(.missingSignatures) {
                    sections.insert(.missingSignatures, at: signaturesIndex + 1)
                }
            }
        }

    }

    func instantiateSignatureDetailsViewControllerWithData(moppLibSignatureDetails: MoppLibSignature) -> Void {
        let signatureDetailsViewController = UIStoryboard.container.instantiateViewController(of: SignatureDetailsViewController.self)
        signatureDetailsViewController.moppLibSignature = moppLibSignatureDetails
        self.navigationController?.pushViewController(signatureDetailsViewController, animated: true)
    }
}

extension ContainerViewController : LandingViewControllerTabButtonsDelegate {
    func landingViewControllerTabButtonTapped(tabButtonId: LandingViewController.TabButtonId, sender: UIView) {
        if tabButtonId == .signButton {
            signingContainerViewDelegate.startSigning()
        }
        else if tabButtonId == .shareButton {
            LandingViewController.shared.shareFile(using: URL(fileURLWithPath: containerPath), sender: sender, completion: { bool in })
        }
        else if tabButtonId == .encryptButton {
            cryptoContainerViewDelegate.startEncrypting()
        }
        else if tabButtonId == .decryptButton {
            cryptoContainerViewDelegate.startDecrypting()
        }
    }
}

extension ContainerViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if containerViewDelegate.isContainerEmpty() {
            return 0
        }
        switch sections[section] {
        case .notifications:
            return notifications.count
        case .signatures:
            if !isAsicContainer {
                return 0
            }
            return asicsSignatures.isEmpty ? signingContainerViewDelegate.getSignaturesCount() : asicsSignatures.count
        case .dataFiles:
            return containerViewDelegate.getDataFileCount()
        case .addressees:
            return cryptoContainerViewDelegate.getAddresseeCount()
        case .missingSignatures, .header, .search, .timestamp, .importDataFiles, .importAddressees, .missingAddressees:
            return 1
        case .containerTimestamps:
            return 1
        }
    }

    func checkIfDdocParentContainerIsTimestamped() -> Void {
        let asicContainer: MoppLibContainer? = self.containerViewDelegate?.getContainer()
        guard let signingContainer: MoppLibContainer = asicContainer else { printLog("Container not found to check timestamped status"); DefaultsHelper.isTimestampedDdoc = false; return }
        
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents: DateComponents = DateComponents(year: 2018, month: 7, day: 1, hour: 00, minute: 00, second: 00)
        guard let calendarDate = calendar.date(from: dateComponents) else { printLog("Unable to get date from calendar components"); DefaultsHelper.isTimestampedDdoc = false; return }
        
        if signingContainer.isAsics(), signingContainer.dataFiles.count == 1, signingContainer.signatures.count == 1,
           let singleFile: MoppLibDataFile = signingContainer.dataFiles[0] as? MoppLibDataFile,
           singleFile.fileName.hasSuffix(ContainerFormatDdoc),
           let singleSignature: MoppLibSignature = signingContainer.signatures[0] as? MoppLibSignature {
            DefaultsHelper.isTimestampedDdoc = !singleSignature.timestamp.isAfter(anotherDate: calendarDate)
            return
        } else if signingContainer.isDdoc(), state != .preview {
            DefaultsHelper.isTimestampedDdoc = false
            return
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        setSections()
        let row = indexPath.row
        switch sections[indexPath.section] {
        case .notifications:
            let cell = tableView.dequeueReusableCell(withType: ContainerNotificationCell.self, for: indexPath)!
            cell.accessibilityUserInputLabels = [""]

            if notifications.indices.contains(indexPath.row) {
                let isSuccess = notifications[indexPath.row].isSuccess
                cell.populate(isSuccess: isSuccess, text: notifications[indexPath.row].text)
                if isSuccess {
                    UIAccessibility.post(notification: .announcement,  argument: cell.infoLabel)
                }
                cell.isAccessibilityElement = false
                return cell
            }
            return ContainerNotificationCell()
        case .signatures:
            let cell = tableView.dequeueReusableCell(withType: ContainerSignatureCell.self, for: indexPath)!
                cell.delegate = self
            cell.accessibilityUserInputLabels = ["\(L(.voiceControlSignature)) \(row + 1)"]
            var signature = asicsSignatures.isEmpty ? (signingContainerViewDelegate.getSignature(index: indexPath.row) as? MoppLibSignature) : asicsSignatures[indexPath.row]
            if isAsicsContainer() && !asicsSignatures.isEmpty && signingContainerViewDelegate.getTimestampTokensCount() > 0 && asicsSignatures.count >= indexPath.row {
                signature = asicsSignatures[indexPath.row]
                let containerExtension: String = URL(fileURLWithPath: containerPath).pathExtension

                if DefaultsHelper.isTimestampedDdoc && (containerExtension == ContainerFormatDdoc ||
                                                        ((containerExtension == ContainerFormatAsics || containerExtension == ContainerFormatAsicsShort) &&
                                                         signingContainerViewDelegate.getTimestampTokensCount() > 0)) {
                    signature?.status = MoppLibSignatureStatus.Valid
                } else if !DefaultsHelper.isTimestampedDdoc && containerExtension == ContainerFormatDdoc && signature?.status != MoppLibSignatureStatus.Invalid {
                    signature?.status = MoppLibSignatureStatus.Warning
                }
            }

            cell.populate(
                with: signature ?? MoppLibSignature(),
                kind: .signature,
                isTimestamp: false,
                showBottomBorder: row < (asicsSignatures.isEmpty ? signingContainerViewDelegate.getSignaturesCount() : asicsSignatures.count) - 1,
                showRemoveButton: !isForPreview && signingContainerViewDelegate.isContainerSignable(),
                signatureIndex: row)
            cell.removeButton.accessibilityLabel = L(.signatureRemoveButton)
            return cell
        case .missingSignatures:
            let cell = tableView.dequeueReusableCell(withType: ContainerNoSignaturesCell.self, for: indexPath)!
            return cell
        case .timestamp:
            let cell = tableView.dequeueReusableCell(withType: ContainerSignatureCell.self, for: indexPath)!
                //cell.populate(name: mockTimestamp[row], kind: .timestamp, colorTheme: .neutral, showBottomBorder: row < mockTimestamp.count - 1)
            cell.accessibilityUserInputLabels = ["\(L(.voiceControlTimestamp)) \(row + 1)"]
            return cell
        case .dataFiles:
            let cell = tableView.dequeueReusableCell(withType: ContainerFileCell.self, for: indexPath)!
                cell.delegate = self
                cell.containerFileUpdatedDelegate = self
            cell.accessibilityTraits = UIAccessibilityTraits.button
            cell.accessibilityUserInputLabels = ["\(L(.voiceControlFileRow)) \(row + 1)"]

            let isStatePreviewOrOpened = state == .opened || state == .preview
            let isEncryptedDataFiles = !isAsicContainer && isStatePreviewOrOpened && !isDecrypted
            
            cell.accessibilityTraits = UIAccessibilityTraits.button
            if !isEncryptedDataFiles {
                cell.accessibilityUserInputLabels = ["\(L(.voiceControlFileRow)) \(row + 1)"]
            } else {
                cell.accessibilityUserInputLabels = [""]
            }

            var dataFileName = ""
            var tapGesture: UITapGestureRecognizer?

            if isAsicsContainer() && !asicsDataFiles.isEmpty && asicsDataFiles.count >= indexPath.row {
                dataFileName = asicsDataFiles[indexPath.row].fileName ?? ContainerViewController.unnamedDataFile
                tapGesture = getPreviewTapGesture(dataFile: dataFileName, containerPath: asicsNestedContainerPath, isShareButtonNeeded: isDecrypted)
            } else {
                dataFileName = containerViewDelegate.getDataFileDisplayName(index: indexPath.row) ?? ContainerViewController.unnamedDataFile
                if !isEncryptedDataFiles {
                    tapGesture = getPreviewTapGesture(dataFile: dataFileName, containerPath: containerViewDelegate.getContainerPath(), isShareButtonNeeded: isDecrypted)
                }
            }

            if dataFileName.isEmpty {
                printLog("Datafile name empty")
                dataFileName = ContainerViewController.unnamedDataFile
            }

            if let tg = tapGesture {
                if !isEncryptedDataFiles {
                    cell.filenameLabel.addGestureRecognizer(tg)
                    tg.isEnabled = true
                } else {
                    if cell.filenameLabel.gestureRecognizers != nil {
                        cell.filenameLabel.removeGestureRecognizer(tg)
                        tg.isEnabled = false
                    }
                }
            }
            
            if isEncryptedDataFiles {
                if let gestureRecognizers = cell.filenameLabel.gestureRecognizers {
                    for gestureRecognizer in gestureRecognizers {
                        if gestureRecognizer is UITapGestureRecognizer {
                            cell.filenameLabel.removeGestureRecognizer(gestureRecognizer)
                        }
                    }
                }
            }

            var isRemoveButtonShown = false
            var isDownloadButtonShown = false
            var isCryptoDocument = false
            if isAsicContainer {
                isRemoveButtonShown = !isForPreview &&
                    (signingContainerViewDelegate.getSignaturesCount() == 0) ||
                (signingContainerViewDelegate.getSignaturesCount() == 0 && signingContainerViewDelegate.isContainerSignable())
                isDownloadButtonShown = true
            } else {
                isRemoveButtonShown = !isEncrypted || isDecrypted
                isDownloadButtonShown = !isForPreview && (isDecrypted || (state != .opened))
                cell.isDownloadButtonRefreshed = false
                isCryptoDocument = true
            }

            cell.populate(
                name: dataFileName,
                containerPath: self.containerViewDelegate.getContainerPath(),
                showBottomBorder: row < self.containerViewDelegate.getDataFileCount() - 1,
                showRemoveButton: isRemoveButtonShown,
                showDownloadButton: isDownloadButtonShown,
                enableDownloadButton: !self.isAsicContainer,
                dataFileIndex: row,
                isCryptoDocument: isCryptoDocument)
            return cell
        case .importDataFiles:
            let cell = tableView.dequeueReusableCell(withType: ContainerImportFilesCell.self, for: indexPath)!
                cell.delegate = self
            return cell
        case .header:
            let cell = tableView.dequeueReusableCell(withType: ContainerHeaderCell.self, for: indexPath)!
            cell.delegate = self
            let isEditingButtonShown: Bool = !isForPreview && (state == .opened)
            cell.populate(name: containerViewDelegate.getContainerFilename(), isEditButtonEnabled: isEditingButtonShown)
            return cell
        case .search:
            let cell = tableView.dequeueReusableCell(withType: ContainerSearchCell.self, for: indexPath)!
            return cell
        case .addressees:
            let cell = tableView.dequeueReusableCell(withType: ContainerAddresseeCell.self, for: indexPath)!
            cell.delegate = self
            let isStatePreviewOrOpened = state == .opened || state == .preview
            let isRemoveButtonHidden = !isAsicContainer && isStatePreviewOrOpened
            cell.populate(addressee: cryptoContainerViewDelegate.getAddressee(index: indexPath.row) as! Addressee,
                          index: row,
                          showRemoveButton: !isRemoveButtonHidden)
            cell.accessibilityUserInputLabels = [""]
            return cell
        case .importAddressees:
            let cell = tableView.dequeueReusableCell(withType: ContainerImportAddresseesCell.self, for: indexPath)!
            cell.delegate = self
            return cell
        case .missingAddressees:
            let cell = tableView.dequeueReusableCell(withType: ContainerNoAddresseesCell.self, for: indexPath)!
            cell.accessibilityUserInputLabels = [""]
            return cell
        case .containerTimestamps:
            let cell = tableView.dequeueReusableCell(withType: ContainerSignatureCell.self, for: indexPath)!
            cell.accessibilityUserInputLabels = ["\(L(.voiceControlContainerTimestamp)) \(row + 1)"]
            var timestampToken: MoppLibSignature = MoppLibSignature()
            if signingContainerViewDelegate.getTimestampTokensCount() >= indexPath.row {
                timestampToken = signingContainerViewDelegate.getTimestampToken(index: indexPath.row) as? MoppLibSignature ?? MoppLibSignature()

                if (containerViewDelegate.getDataFileCount() == 1 && isSendingToSivaAgreed && !isLoadingNestedAsicsDone) {
                    updateState(.loading)
                    let dataFile = containerViewDelegate.getDataFileDisplayName(index: 0) ?? ""
                    let containerFilePath = containerViewDelegate.getContainerPath()
                    let destinationPath = MoppFileManager.shared.tempFilePath(withFileName: dataFile)
                    self.openNestedContainer(containerFilePath: containerFilePath, dataFile: dataFile, destinationPath: destinationPath)
                } else if (!isLoadingNestedAsicsDone) {
                    cell.populate(
                        with: timestampToken,
                        kind: .timestamp,
                        isTimestamp: true,
                        showBottomBorder: row < signingContainerViewDelegate.getTimestampTokensCount() - 1,
                        showRemoveButton: false,
                        signatureIndex: row)
                } else {
                    updateState(.opened)
                }
            } else {
                return UITableViewCell()
            }

            cell.populate(
                with: timestampToken,
                kind: .timestamp,
                isTimestamp: true,
                showBottomBorder: row < self.signingContainerViewDelegate.getTimestampTokensCount() - 1,
                showRemoveButton: false,
                signatureIndex: row)

            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !isAsicsInitialLoadingDone && isAsicsContainer() && isDeviceOrientationLandscape() {
            scrollTableView(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !isAsicsInitialLoadingDone && isAsicsContainer() && isDeviceOrientationLandscape() {
            isAsicsInitialLoadingDone = true
        }
    }
    
    // On landscape, ASICS may not load correctly as all cells are not loaded when container is opened
    // Using scroll to load more cells, so that nested container will be loaded
    private func scrollTableView(_ indexPath: IndexPath) {
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    private func openNestedContainer(containerFilePath: String, dataFile: String, destinationPath: String?) {
        MoppLibContainerActions.sharedInstance().container(containerFilePath, saveDataFile: dataFile, to: destinationPath) {
            MoppLibContainerActions.sharedInstance().openContainer(withPath: destinationPath) { container in
                if let signatures = container?.signatures {
                    for signature in signatures {
                        self.asicsSignatures.append(signature as? MoppLibSignature ?? MoppLibSignature())
                    }
                }

                if let dataFiles = container?.dataFiles {
                    for dataFile in dataFiles {
                        self.asicsDataFiles.append(dataFile as? MoppLibDataFile ?? MoppLibDataFile())
                    }
                }

                self.asicsNestedContainerPath = destinationPath ?? ""

                self.isLoadingNestedAsicsDone = true

                self.reloadData()
            } failure: { error in
                self.isLoadingNestedAsicsDone = true
                self.isSendingToSivaAgreed = false
                self.reloadContainer()
            }

        } failure: { error in
            printLog("Unable to get file from container \(error?.localizedDescription ?? "Unable to get error description")")
            let nserror = error as NSError?
            if nserror != nil && nserror?.code == Int(MoppLibErrorCode.moppLibErrorNoInternetConnection.rawValue) {
                let pathExtension = URL(string: containerFilePath)?.pathExtension
                if pathExtension == "asics" || pathExtension == "scs" {
                    SiVaUtil.displaySendingToSiVaDialog { hasAgreed in
                        if hasAgreed {
                            self.openNestedContainer(containerFilePath: containerFilePath, dataFile: dataFile, destinationPath: destinationPath)
                            return
                        } else {
                            self.navigationController?.popViewController(animated: true)
                            return
                        }
                    }
                }
            }
            self.errorAlert(message: L(.fileImportOpenExistingFailedAlertMessage, [dataFile]))
        }
    }

    @objc private func openPreview(_ sender: PreviewFileTapGestureRecognizer) {
        guard let dataFile: String = sender.dataFile, let containerFilePath: String = sender.containerFilePath, let isShareButtonNeeded: Bool = sender.isShareButtonNeeded else {
            printLog("Unable to get data file, container file or share button information")
            self.errorAlert(message: L(.datafilePreviewFailed))
            return
        }

        if isAsicsContainer() && !asicsNestedContainerPath.isEmpty {
            openFilePreview(dataFileFilename: dataFile, containerFilePath: asicsNestedContainerPath, isShareButtonNeeded: isShareButtonNeeded)
        } else {
            openFilePreview(dataFileFilename: dataFile, containerFilePath: containerFilePath, isShareButtonNeeded: isShareButtonNeeded)
        }
    }

    private func getPreviewTapGesture(dataFile: String, containerPath: String, isShareButtonNeeded: Bool) -> PreviewFileTapGestureRecognizer {
        let tapGesture: PreviewFileTapGestureRecognizer = PreviewFileTapGestureRecognizer(target: self, action: #selector(openPreview(_:)))

        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1

        tapGesture.dataFile = dataFile
        tapGesture.containerFilePath = containerViewDelegate.getContainerPath()
        tapGesture.isShareButtonNeeded = isDecrypted

        return tapGesture
    }
}

extension ContainerViewController : ContainerFileDelegate {
    func removeDataFile(dataFileIndex: Int) {
        containerViewDelegate.removeDataFile(index: dataFileIndex)
    }

    func saveDataFile(fileName: String?) {
        containerViewDelegate.saveDataFile(name: fileName, containerPath: asicsNestedContainerPath)
    }
}

extension ContainerViewController : ContainerHeaderDelegate {

    private func asicContainerExists(container: MoppLibContainer?) -> Bool {
        guard let signingContainer: MoppLibContainer = container,
              let signingContainerFilePath = signingContainer.filePath,
              !(signingContainerFilePath as String).isEmpty,
              URL(fileURLWithPath: signingContainerFilePath).pathExtension != ContainerFormatCdoc else {
            return false
        }

        return true
    }

    private func cdocContainerExists(container: CryptoContainer?) -> Bool {
        guard let cryptoContainer: CryptoContainer = container,
              let cryptoContainerFilePath = cryptoContainer.filePath,
              !(cryptoContainerFilePath as String).isEmpty,
              URL(fileURLWithPath: cryptoContainerFilePath as String).pathExtension == ContainerFormatCdoc else {
            return false
        }

        return true
    }

    private func getNewContainerUrlPath(isContainerCdoc: Bool, asicContainer: MoppLibContainer?, cdocContainer: CryptoContainer?, newContainerName: String, containerExtension: String) -> URL? {
        var newContainerPath: URL? = URL(string: "")
        if let signingContainer = asicContainer, !isContainerCdoc {
            newContainerPath = URL(fileURLWithPath: signingContainer.filePath as String)
        } else if let cryptoContainer = cdocContainer, isContainerCdoc {
            newContainerPath = URL(fileURLWithPath: cryptoContainer.filePath as String)
        }

        guard let containerPath = newContainerPath else { return nil }

        return containerPath.deletingLastPathComponent().appendingPathComponent(newContainerName).appendingPathExtension(containerExtension)
    }

    func editContainerName(completion: @escaping (_ fileName: String) -> Void) {

        var currentFileName: String = ""
        var containerExtension: String = ""

        let asicContainer: MoppLibContainer? = self.containerViewDelegate?.getContainer()
        let cdocContainer: CryptoContainer? = self.cryptoContainerViewDelegate?.getContainer()

        if asicContainerExists(container: asicContainer), let signingContainer = asicContainer {
            currentFileName = URL(fileURLWithPath: signingContainer.filePath).deletingPathExtension().lastPathComponent
            containerExtension = URL(fileURLWithPath: signingContainer.filePath).pathExtension
        } else if cdocContainerExists(container: cdocContainer), let cryptoContainer = cdocContainer {
            currentFileName = URL(fileURLWithPath: cryptoContainer.filePath as String).deletingPathExtension().lastPathComponent
            containerExtension = URL(fileURLWithPath: (cryptoContainer.filePath as String)).pathExtension
        }

        guard !containerExtension.isEmpty else {
            printLog("Failed to get container extension")
            self.errorAlert(message: L(.containerErrorMessageFailedContainerNameChange))
            return
        }

        let changeContainerNameController = UIAlertController(title: L(.containerEditNameButton), message: nil, preferredStyle: UIAlertController.Style.alert)
        let cancelButton = UIAlertAction(title: L(.actionCancel), style: UIAlertAction.Style.cancel) { _ in
            if UIAccessibility.isVoiceOverRunning {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .announcement, argument: L(.containerNameChangeCancelled))
                }
            }
        }
        changeContainerNameController.addAction(cancelButton)

        let okButton = UIAlertAction(title: L(.actionOk), style: UIAlertAction.Style.default) { (action: UIAlertAction) in
            guard let textFields = changeContainerNameController.textFields, textFields.count != 0, let textFieldText = textFields[0].text else {
                printLog("Failed to find textfield")
                self.errorAlert(message: L(.containerErrorMessageFailedContainerNameChange))
                return
            }

            let isContainerCdoc: Bool = containerExtension == ContainerFormatCdoc

            guard let newContainerPath: URL = self.getNewContainerUrlPath(isContainerCdoc: isContainerCdoc, asicContainer: asicContainer, cdocContainer: cdocContainer, newContainerName: textFieldText, containerExtension: containerExtension), newContainerPath.isFileURL else {
                printLog("Failed to get container path")
                self.errorAlert(message: L(.containerErrorMessageFailedContainerNameChange))
                return
            }
            
            if asicContainer?.filePath != newContainerPath.path {

            // Remove existing file
            if MoppFileManager.shared.fileExists(newContainerPath.path) {
                MoppFileManager.shared.removeFile(withPath: newContainerPath.path)
            }

            // Rename / save file
            if !isContainerCdoc {
                guard let signingContainer = asicContainer, MoppFileManager.shared.moveFile(withPath: signingContainer.filePath, toPath: newContainerPath.path, overwrite: true) else {
                    printLog("Failed to change asic file properties")
                    self.errorAlert(message: L(.containerErrorMessageFailedContainerNameChange))
                    return
                }
                signingContainer.fileName = newContainerPath.lastPathComponent
                signingContainer.filePath = newContainerPath.path
            } else {
                guard let cryptoContainer = cdocContainer else {
                    printLog("Failed to change cdoc file properties")
                    self.errorAlert(message: L(.containerErrorMessageFailedContainerNameChange))
                    return
                }
                cryptoContainer.filename = newContainerPath.lastPathComponent as NSString
                cryptoContainer.filePath = newContainerPath.path as NSString
            }

            printLog("File renaming successful")

            if UIAccessibility.isVoiceOverRunning {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .announcement, argument: L(.containerNameChanged))
                }
            }

            self.containerPath = newContainerPath.path
            self.tableView.reloadData()

            return completion(newContainerPath.lastPathComponent)
            } else {
                return completion(URL(string: asicContainer?.filePath ?? "")?.lastPathComponent ?? "")
            }
        }

        changeContainerNameController.addAction(okButton)

        changeContainerNameController.addTextField { (textField: UITextField) in
            textField.text = currentFileName
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: OperationQueue.main) { (notification) in
                guard let inputText = textField.text else {
                    printLog("Failed to get textfield's text")
                    self.errorAlert(message: L(.containerErrorMessageFailedContainerNameChange))
                    return
                }
                if inputText.count == 0 || inputText.starts(with: ".") {
                     okButton.isEnabled = false
                 } else {
                     okButton.isEnabled = true
                 }
             }
         }

         self.present(changeContainerNameController, animated: true, completion: nil)
     }

     func scrollToTop() {
         let indexPath = IndexPath(row: 0, section: 0)
         self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
     }
 }

extension ContainerViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .notifications:
            break
        case .signatures:
            if let signature = getSignature(indexPathRow: indexPath.row) {
                instantiateSignatureDetailsViewControllerWithData(moppLibSignatureDetails: signature)
            }
            break
        case .missingSignatures:
            break
        case .timestamp:
            break;
        case .dataFiles:
            break
        case .header:
            break
        case .search:
            break
        case .importDataFiles:
            break
        case .addressees:
            break
        case .importAddressees:
            break
        case .missingAddressees:
            break
        case .containerTimestamps:
            if let token = getTimestampToken(indexPathRow: indexPath.row) {
                instantiateSignatureDetailsViewControllerWithData(moppLibSignatureDetails: token)
            }
            break
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section]
        var title: String!
        switch section {
        case .dataFiles:
            if isCreated && !isAsicContainer {
                title = L(.cryptoHeaderFilesTitle)
            } else if isEncrypted {
                title = L(.cryptoEncryptedFilesTitle)
            } else {
                title = L(.containerHeaderFilesTitle)
            }
        default:
            title = sectionHeaderTitle[section]
        }

        if let header = MoppApp.instance.nibs[.containerElements]?.instantiate(withOwner: self, type: ContainerTableViewHeaderView.self) {
            var signaturesCount = 0
            var isContainerSignable = false
            if isAsicContainer {
                signaturesCount = asicsSignatures.isEmpty ? signingContainerViewDelegate.getSignaturesCount() : asicsSignatures.count
                isContainerSignable = signingContainerViewDelegate.isContainerSignable()
            }

            header.delegate = self
            header.populate(
                withTitle: title ?? "",
                showAddButton:
                    section == .dataFiles   &&
                    !isCreated              &&
                    signaturesCount == 0    &&
                    !isForPreview           &&
                    isContainerSignable)
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
        if containerViewDelegate.isContainerEmpty() {
            return
        }
        if isForPreview {
            updateState(.preview)
        }
        else if isSignaturesEmpty && isCreated {
            updateState(.created)
        }
        else {
            updateState(.opened)
        }
        if isAsicContainer {
            if isSignaturesEmpty {
                    sections = (isForPreview || !isCreated) ? ContainerViewController.sectionsDefault : ContainerViewController.sectionsNoSignatures
                if let signaturesIndex = sections.firstIndex(where: { $0 == .signatures }) {
                    if !sections.contains(.missingSignatures) {
                        sections.insert(.missingSignatures, at: signaturesIndex + 1)
                    }
                }
            }
            else {
                if isAsicsContainer() {
                    sections = isSendingToSivaAgreed ? ContainerViewController.sectionsWithTimestamp :
                    ContainerViewController.sectionsWithTimestampNoSignatures
                } else {
                    sections = ContainerViewController.sectionsDefault
                }
            }
        }

        tableView.reloadData()

        // Animate away success message if there is any
        if let notificationIndex = notifications.firstIndex(where: { $0.isSuccess == true }), sections.contains(.notifications) {
            scrollToTop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let notificationMessages = self?.notifications, !notificationMessages.isEmpty else { return }
                if notificationMessages.indices.contains(notificationIndex) {
                    self?.notifications.remove(at: notificationIndex)
                    if let notificationsSection = self?.sections.firstIndex(where: { $0 == .notifications }) {
                        self?.tableView.reloadSections([notificationsSection], with: .automatic)
                    }
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let _ = segue.destination as? SignatureDetailsViewController {
            let mopplibSignatureDetails = sender as? MoppLibSignature
            let signatureDetailsViewController = UIStoryboard.container.instantiateViewController(of: SignatureDetailsViewController.self)
            signatureDetailsViewController.moppLibSignature = mopplibSignatureDetails
            self.navigationController?.pushViewController(signatureDetailsViewController, animated: true)
        }
    }
    
    private func getSignature(indexPathRow: Int) -> MoppLibSignature? {
        if !asicsSignatures.isEmpty && asicsSignatures.indices.contains(indexPathRow) {
            return asicsSignatures[indexPathRow]
        }
        return signingContainerViewDelegate.getSignature(index: indexPathRow) as? MoppLibSignature
    }
    
    private func getTimestampToken(indexPathRow: Int) -> MoppLibSignature? {
        return signingContainerViewDelegate.getTimestampToken(index: indexPathRow) as? MoppLibSignature
    }
}

extension ContainerViewController : ContainerSignatureDelegate {
    func containerSignatureRemove(signatureIndex: Int) {
        signingContainerViewDelegate.removeSignature(index: signatureIndex)
    }
}

extension ContainerViewController : ContainerTableViewHeaderDelegate {
    func didTapContainerHeaderButton() {
        guard let landingViewControllerContainerType = LandingViewController.shared.containerType else {
            printLog("Unable to get LandingViewControlelr container type")
            return
        }
        NotificationCenter.default.post(
            name: .startImportingFilesWithDocumentPickerNotificationName,
            object: nil,
            userInfo: [kKeyFileImportIntent: MoppApp.FileImportIntent.addToContainer, kKeyContainerType: landingViewControllerContainerType])
    }
}

extension ContainerViewController : ContainerImportAddresseeCellDelegate {
    func containerImportCellAddAddressee() {
        cryptoContainerViewDelegate.addAddressees()
    }
}

extension ContainerViewController : ContainerAddresseeCellDelegate {
    func removeAddressee(index: Int) {
        cryptoContainerViewDelegate.removeSelectedAddressee(index: index)
        UIAccessibility.post(notification: .screenChanged, argument: L(.cryptoRecipientRemoved))
    }

}

extension ContainerViewController : ContainerImportCellDelegate {
    func containerImportCellAddFiles() {
        guard let landingViewControllerContainerType = LandingViewController.shared.containerType else {
            printLog("Unable to get LandingViewControlelr container type")
            return
        }
        NotificationCenter.default.post(
            name: .startImportingFilesWithDocumentPickerNotificationName,
            object: nil,
            userInfo: [kKeyFileImportIntent: MoppApp.FileImportIntent.addToContainer, kKeyContainerType: landingViewControllerContainerType])
    }
}

extension ContainerViewController {
    func getCachedIsSaveable(for indexPath: IndexPath) -> Bool? {
        return isFileSaveableCache[indexPath]
    }
    
    func setCachedIsSaveable(_ result: Bool, for indexPath: IndexPath) {
        isFileSaveableCache[indexPath] = result
    }
    
    func clearIsSaveableCache() {
        isFileSaveableCache.removeAll()
    }
}

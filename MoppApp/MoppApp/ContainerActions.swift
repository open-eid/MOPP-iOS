//
//  ContainerActions.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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
protocol ContainerActions {
    func openExistingContainer(with url: URL, cleanup: Bool, isEmptyFileImported: Bool)
    func importFiles(with urls: [URL], cleanup: Bool, isEmptyFileImported: Bool)
    func addDataFilesToContainer(dataFilePaths: [String])
    func createNewContainer(with url: URL, dataFilePaths: [String], isEmptyFileImported: Bool, startSigningWhenCreated: Bool, cleanUpDataFilesInDocumentsFolder: Bool)
    func createNewContainerForNonSignableContainerAndSign()
}

extension ContainerActions where Self: UIViewController {
    func importFiles(with urls: [URL], cleanup: Bool, isEmptyFileImported: Bool) {
        let landingViewController = LandingViewController.shared!
        let navController = landingViewController.viewController(for: .signTab) as! UINavigationController
        let topSigningViewController = navController.viewControllers.last!
        
        landingViewController.documentPicker.dismiss(animated: false, completion: nil)
        
        if urls.count == 1 && SiVaUtil.isDocumentSentToSiVa(fileUrl: urls.first) {
            SiVaUtil.displaySendingToSiVaDialog { hasAgreed in
                if hasAgreed {
                    self.importDataFiles(with: urls, navController: navController, topSigningViewController: topSigningViewController, landingViewController: landingViewController, cleanup: cleanup, isEmptyFileImported: isEmptyFileImported)
                }
            }
            return
        } else {
            self.importDataFiles(with: urls, navController: navController, topSigningViewController: topSigningViewController, landingViewController: landingViewController, cleanup: cleanup, isEmptyFileImported: isEmptyFileImported)
        }
    }
    
    func importDataFiles(with urls: [URL], navController: UINavigationController, topSigningViewController: UIViewController, landingViewController: LandingViewController, cleanup: Bool, isEmptyFileImported: Bool) {
        if topSigningViewController.presentedViewController is FileImportProgressViewController {
            topSigningViewController.presentedViewController?.errorAlert(message: L(.fileImportAlreadyInProgressMessage))
            return
        }
        
        topSigningViewController.present(landingViewController.importProgressViewController, animated: false)
        
        MoppFileManager.shared.importFiles(with: urls) { [weak self] error, dataFilePaths in
            
            if error != nil {
                NSLog(error?.localizedDescription ?? "No error description")
                if topSigningViewController.presentedViewController is FileImportProgressViewController {
                    self?.dismiss(animated: true, completion: {
                        if let nsError = error as NSError?, !nsError.userInfo.isEmpty, nsError.userInfo[NSLocalizedDescriptionKey] != nil {
                            self?.showErrorMessage(title: L(.fileImportOpenExistingFailedAlertTitle), message: nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? L(.fileImportOpenExistingFailedAlertMessage, [""]))
                        } else {
                            self?.showErrorMessage(title: L(.fileImportOpenExistingFailedAlertTitle), message: L(.fileImportOpenExistingFailedAlertMessage, [""]))
                        }
                    })
                }
                return
            }

            if landingViewController.fileImportIntent == .addToContainer {
                landingViewController.addDataFilesToContainer(dataFilePaths: dataFilePaths)
            }
            else if landingViewController.fileImportIntent == .openOrCreate {
                navController.setViewControllers([navController.viewControllers.first!], animated: false)
             
                let ext = urls.first!.pathExtension
                if landingViewController.containerType == nil {
                    if ext.isCdocContainerExtension {
                        landingViewController.containerType = .cdoc
                    } else {
                        landingViewController.containerType = .asic
                    }
                }
                let isAsicOrPadesContainer = (ext.isAsicContainerExtension || ext == ContainerFormatPDF) &&
                    landingViewController.containerType == .asic
                let isCdocContainer = ext.isCdocContainerExtension && landingViewController.containerType == .cdoc
                if  (isAsicOrPadesContainer || isCdocContainer) && urls.count == 1 {
                    self?.openExistingContainer(with: urls.first!, cleanup: cleanup, isEmptyFileImported: isEmptyFileImported)
                } else {
                    self?.createNewContainer(with: urls.first!, dataFilePaths: dataFilePaths, isEmptyFileImported: isEmptyFileImported)
                }
            }
        }
    }
    
    func openExistingContainer(with url: URL, cleanup: Bool, isEmptyFileImported: Bool) {
    
        let landingViewController = LandingViewController.shared!
    
        // Move container from inbox folder to documents folder and cleanup.
        let filePath = url.relativePath
        let fileName = url.lastPathComponent
        
        // Used to access folders on user device when opening container outside app (otherwise gives "Operation not permitted" error)
        url.startAccessingSecurityScopedResource()

        let navController = landingViewController.viewController(for: .signTab) as? UINavigationController

        var newFilePath: String = MoppFileManager.shared.filePath(withFileName: fileName)
            newFilePath = MoppFileManager.shared.copyFile(withPath: filePath, toPath: newFilePath)

        if (cleanup) {
            MoppFileManager.shared.removeFile(withPath: filePath)
        }

        let failure: ((_ error: NSError?) -> Void) = { err in
            
            landingViewController.importProgressViewController.dismissRecursivelyIfPresented(animated: false, completion: nil)
            
            var alert: UIAlertController
            guard err?.code == 10005 && (url.lastPathComponent.hasSuffix(ContainerFormatDdoc) || url.lastPathComponent.hasSuffix(ContainerFormatPDF)) else {
                alert = UIAlertController(title: L(.fileImportOpenExistingFailedAlertTitle), message: L(.fileImportOpenExistingFailedAlertMessage, [fileName]), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))
                
                navController?.viewControllers.last!.present(alert, animated: true)
                return
            }
            
            alert = UIAlertController(title: L(.fileImportOpenExistingFailedAlertTitle), message: L(.noConnectionMessage), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))
            
            if isEmptyFileImported {
                navController?.viewControllers.last!.present(alert, animated: true, completion: {
                    navController?.viewControllers.last!.showErrorMessage(title: L(.errorAlertTitleGeneral), message: L(.fileImportFailedEmptyFile))
                })
            }
        }
        if landingViewController.containerType == .asic {
            MoppLibContainerActions.sharedInstance().openContainer(withPath: newFilePath,
                success: { (_ container: MoppLibContainer?) -> Void in
                    if container == nil {
                        // Remove invalid container. Probably ddoc.
                        MoppFileManager.shared.removeFile(withName: fileName)
                        failure(nil)
                        return
                    }
                
                    // If file to open is PDF and there is no signatures then create new container
                    let isPDF = url.pathExtension.lowercased() == ContainerFormatPDF
                    if isPDF && container!.signatures.isEmpty {
                        landingViewController.createNewContainer(with: url, dataFilePaths: [newFilePath], isEmptyFileImported: isEmptyFileImported)
                        return
                    }
                    
                    var containerViewController: ContainerViewController? = ContainerViewController.instantiate()
                        containerViewController?.containerPath = newFilePath
                        containerViewController?.forcePDFContentPreview = isPDF
                    
                    landingViewController.importProgressViewController.dismissRecursively(animated: false, completion: {
                        if let containerVC = containerViewController {
                            navController?.pushViewController(containerVC, animated: true)
                            containerViewController = nil
                        }
                    })

                },
                failure: { error in
                    guard let nsError = error as NSError? else { failure(nil); return }
                    failure(nsError)
                }
            )
        } else {
            let containerViewController = CryptoContainerViewController.instantiate()
            let container = CryptoContainer(filename: fileName as NSString, filePath: newFilePath as NSString)
            
            MoppLibCryptoActions.sharedInstance().parseCdocInfo(
                newFilePath as String?,
                success: {(_ cdocInfo: CdocInfo?) -> Void in
                    guard let strongCdocInfo = cdocInfo else { return }
                    container.addressees = strongCdocInfo.addressees
                    container.dataFiles = strongCdocInfo.dataFiles
                    containerViewController.containerPath = newFilePath
                    containerViewController.state = .opened
                    containerViewController.container = container
                    containerViewController.isContainerEncrypted = true
                    landingViewController.importProgressViewController.dismissRecursively(animated: false, completion: {
                        navController?.pushViewController(containerViewController, animated: true)
                    })
                },
                failure: { _ in
                    DispatchQueue.main.async {
                         failure(nil)
                    }
                }
            )
        }
        url.stopAccessingSecurityScopedResource()
    }

    func addDataFilesToContainer(dataFilePaths: [String]) {
        let landingViewController = LandingViewController.shared!
        let navController = landingViewController.viewController(for: .signTab) as! UINavigationController
        let topSigningViewController = navController.viewControllers.last!

        if landingViewController.containerType == .asic {
            let containerViewController = topSigningViewController as? ContainerViewController
            let containerPath = containerViewController!.containerPath
            MoppLibContainerActions.sharedInstance().addDataFilesToContainer(
                withPath: containerPath,
                withDataFilePaths: dataFilePaths,
                success: { container in
                    landingViewController.importProgressViewController.dismissRecursively(animated: false, completion: {
                        if dataFilePaths.count == 1 {
                            UIAccessibility.post(notification: .announcement, argument: L(.dataFileAdded))
                        } else if dataFilePaths.count > 1 {
                            UIAccessibility.post(notification: .announcement, argument: L(.dataFilesAdded))
                        }
                        containerViewController?.reloadContainer()
                    })
                },
                failure: { error in
                    landingViewController.importProgressViewController.dismissRecursively(animated: false, completion: {
                        guard let nsError = error as NSError? else { return }
                        if nsError.code == Int(MoppLibErrorCode.moppLibErrorDuplicatedFilename.rawValue) {
                            DispatchQueue.main.async {
                                self.errorAlert(message: L(.containerDetailsFileAlreadyExists))
                            }
                        }
                    })
                }
            )
        } else {
            let containerViewController = topSigningViewController as? CryptoContainerViewController
            dataFilePaths.forEach {
                let filename = ($0 as NSString).lastPathComponent as NSString
                if isDuplicatedFilename(container: (containerViewController?.container)!, filename: filename) {
                    DispatchQueue.main.async {
                        self.errorAlert(message: L(.containerDetailsFileAlreadyExists))
                    }
                    return
                }
                let dataFile = CryptoDataFile.init()
                dataFile.filename = filename as String?
                dataFile.filePath = $0
                
                containerViewController?.container.dataFiles.add(dataFile)
            }
            
            landingViewController.importProgressViewController.dismissRecursively(animated: false, completion: {
                containerViewController?.reloadContainer()
            })
        }
    }
    
    private func isDuplicatedFilename(container: CryptoContainer, filename: NSString) -> Bool {
        for dataFile in container.dataFiles {
            if let strongDataFile = dataFile as? CryptoDataFile {
                if strongDataFile.filename as NSString == filename {
                    return true
                }
            }
        }
        return false
    }
    
    func createNewContainer(with url: URL, dataFilePaths: [String], isEmptyFileImported: Bool, startSigningWhenCreated: Bool = false, cleanUpDataFilesInDocumentsFolder: Bool = true) {
        let landingViewController = LandingViewController.shared!
    
        let filePath = url.relativePath
        let fileName: String = MoppLibManager.sanitize(url.lastPathComponent)
        
        let containerFilePaths = sanitizeDataFilePaths(dataFilePaths: dataFilePaths)
        
        let (filename, _) = fileName.filenameComponents()
        let containerFilename: String
        if landingViewController.containerType == .asic {
            containerFilename = filename + "." + DefaultContainerFormat
        }else{
            containerFilename = filename + "." + ContainerFormatCdoc
        }
        
        var containerPath = MoppFileManager.shared.filePath(withFileName: containerFilename)
            containerPath = MoppFileManager.shared.duplicateFilename(atPath: containerPath)

        let navController = landingViewController.viewController(for: .signTab) as? UINavigationController

        let cleanUpDataFilesInDocumentsFolderCode: () -> Void = {
            containerFilePaths.forEach {
                if $0.hasPrefix(MoppFileManager.shared.documentsDirectoryPath()) {
                    MoppFileManager.shared.removeFile(withPath: $0)
                }
            }
            MoppFileManager.shared.removeFilesFromSharedFolder()
        }
        if landingViewController.containerType == .asic {
            MoppLibContainerActions.sharedInstance().createContainer(
                withPath: containerPath,
                withDataFilePaths: containerFilePaths,
                success: { container in
                    if cleanUpDataFilesInDocumentsFolder {
                        cleanUpDataFilesInDocumentsFolderCode()
                    }
                    if container == nil {
                        
                        landingViewController.importProgressViewController.dismissRecursively(animated: false, completion: nil)
                        
                        let alert = UIAlertController(title: L(.fileImportCreateNewFailedAlertTitle), message: L(.fileImportCreateNewFailedAlertMessage, [fileName]), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))
                        
                        landingViewController.present(alert, animated: true)
                        return
                    }
                    
                    let containerViewController = SigningContainerViewController.instantiate()
                    containerViewController.containerPath = containerPath
                    
                    containerViewController.isCreated = true
                    containerViewController.startSigningWhenOpened = startSigningWhenCreated
                    
                    landingViewController.importProgressViewController.dismissRecursively(animated: false, completion: {
                        if containerFilePaths.count == 1 {
                            UIAccessibility.post(notification: .announcement, argument: L(.dataFileAdded))
                        } else if containerFilePaths.count > 1 {
                            UIAccessibility.post(notification: .announcement, argument: L(.dataFilesAdded))
                        }
                        navController?.pushViewController(containerViewController, animated: true)
                        if isEmptyFileImported {
                            containerViewController.showErrorMessage(title: L(.errorAlertTitleGeneral), message: L(.fileImportFailedEmptyFile))
                        }
                    })
                    
            }, failure: { error in
                if cleanUpDataFilesInDocumentsFolder {
                    cleanUpDataFilesInDocumentsFolderCode()
                }
                landingViewController.importProgressViewController.dismiss(animated: false, completion: nil)
                MoppFileManager.shared.removeFile(withPath: filePath)
            }
            )
        } else {

            let containerViewController = CryptoContainerViewController.instantiate()
            let container = CryptoContainer(filename: containerFilename as NSString, filePath: containerPath as NSString)
            containerViewController.containerPath = containerPath
            
            for dataFilePath in containerFilePaths {
                let dataFile = CryptoDataFile.init()
                dataFile.filename = (dataFilePath as NSString).lastPathComponent
                dataFile.filePath = dataFilePath
                container.dataFiles.add(dataFile)
            }
            
            containerViewController.container = container
            containerViewController.isCreated = true
            
            landingViewController.importProgressViewController.dismissRecursively(animated: false, completion: {
                navController?.pushViewController(containerViewController, animated: true)
            })
        }

    }
    
    func createNewContainerForNonSignableContainerAndSign() {
        if let containerViewController = self as? ContainerViewController {
            let containerPath = containerViewController.containerPath!
            let containerPathURL = URL(fileURLWithPath: containerPath)
            createNewContainer(with: containerPathURL, dataFilePaths: [containerPath], isEmptyFileImported: MoppFileManager.isFileEmpty(fileUrl: containerPathURL), startSigningWhenCreated: true, cleanUpDataFilesInDocumentsFolder: false)
        }
    }
    
    func sanitizeDataFilePaths(dataFilePaths: [String]) -> [String] {
        var containerFilePaths: [String] = []
        for dataFile in dataFilePaths {
            let dataFileUrl = URL(fileURLWithPath: dataFile)
            let dataFileName = dataFileUrl.lastPathComponent
            let sanitizedUrlFolder = dataFileUrl.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("temp", isDirectory: true)
            let sanitizedUrl = sanitizedUrlFolder.appendingPathComponent(MoppLibManager.sanitize(dataFileName), isDirectory: false)
            if dataFileName != sanitizedUrl.lastPathComponent && MoppFileManager.shared.fileExists(dataFileUrl.path) {
                try? MoppFileManager.shared.fileManager.createDirectory(at: sanitizedUrlFolder, withIntermediateDirectories: true, attributes: nil)
                let newUrl = MoppFileManager.shared.copyFile(withPath: dataFileUrl.path, toPath: sanitizedUrl.path)
                containerFilePaths.append(newUrl)
            } else {
                containerFilePaths.append(dataFile)
            }
        }
        return containerFilePaths
    }
}

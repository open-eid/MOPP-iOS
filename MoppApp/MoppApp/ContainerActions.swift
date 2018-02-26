//
//  ContainerActions.swift
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
protocol ContainerActions {
    func openExistingContainer(with url: URL)
    func importFiles(with urls: [URL])
    func addDataFilesToContainer(dataFilePaths: [String])
    func createNewContainer(with url: URL, dataFilePaths: [String], startSigningWhenCreated: Bool, cleanUpDataFilesInDocumentsFolder: Bool)
    func createLegacyContainer()
}

extension ContainerActions where Self: UIViewController {
    func openExistingContainer(with url: URL) {
    
        let landingViewController = LandingViewController.shared!
    
        // Move container from inbox folder to documents folder and cleanup.
        let filePath = url.relativePath
        let fileName = url.lastPathComponent

        let navController = landingViewController.viewControllers[0] as! UINavigationController

        var newFilePath: String = MoppFileManager.shared.filePath(withFileName: fileName)
            newFilePath = MoppFileManager.shared.copyFile(withPath: filePath, toPath: newFilePath)

        MoppFileManager.shared.removeFile(withPath: filePath)

        let failure: (() -> Void) = {
            
            landingViewController.importProgressViewController.dismiss(animated: false, completion: nil)
            
            let alert = UIAlertController(title: L(.fileImportOpenExistingFailedAlertTitle), message: L(.fileImportOpenExistingFailedAlertMessage, [fileName]), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))

            navController.viewControllers.first!.present(alert, animated: true)
        }

        MoppLibContainerActions.sharedInstance().getContainerWithPath(newFilePath,
            success: { (_ container: MoppLibContainer?) -> Void in
                if container == nil {
                    // Remove invalid container. Probably ddoc.
                    MoppFileManager.shared.removeFile(withName: fileName)
                    failure()
                    return
                }
            
                landingViewController.importProgressViewController.dismiss(animated: false, completion: nil)
            
                // If file to open is PDF and there is no signatures then create new container
                let isPDF = url.pathExtension.lowercased() == ContainerFormatPDF
                if isPDF && container!.signatures.isEmpty {
                    landingViewController.createNewContainer(with: url, dataFilePaths: [newFilePath])
                    return
                }
            
                landingViewController.selectedTab = .signTab
                
                let containerViewController = ContainerViewController.instantiate()
                    containerViewController.containerPath = newFilePath
                    containerViewController.forcePDFContentPreview = isPDF
                
                navController.pushViewController(containerViewController, animated: true)
            },
            failure: { _ in
                failure()
            }
        )
    }
    func importFiles(with urls: [URL]) {
        let landingViewController = LandingViewController.shared!
        let navController = landingViewController.viewControllers[0] as! UINavigationController
        let topSigningViewController = navController.viewControllers.last!
        
        landingViewController.documentPicker.dismiss(animated: false, completion: nil)
        
        topSigningViewController.present(landingViewController.importProgressViewController, animated: false)
        
        MoppFileManager.shared.importFiles(with: urls) { [weak self] error, dataFilePaths in
        
            if landingViewController.fileImportIntent == .addToContainer {
                landingViewController.addDataFilesToContainer(dataFilePaths: dataFilePaths)
            }
            else if landingViewController.fileImportIntent == .openOrCreate {
                navController.setViewControllers([navController.viewControllers.first!], animated: false)
             
                let ext = urls.first!.pathExtension
                if (ext.isContainerExtension || ext == ContainerFormatPDF) && urls.count == 1 {
                    self?.openExistingContainer(with: urls.first!)
                } else {
                    self?.createNewContainer(with: urls.first!, dataFilePaths: dataFilePaths)
                }
            }
        }
    }

    func addDataFilesToContainer(dataFilePaths: [String]) {
        let landingViewController = LandingViewController.shared!
        let navController = landingViewController.viewControllers[0] as! UINavigationController
        let topSigningViewController = navController.viewControllers.last!
        let containerViewController = topSigningViewController as? ContainerViewController
        let containerPath = containerViewController!.containerPath
        MoppLibContainerActions.sharedInstance().addDataFilesToContainer(
            withPath: containerPath,
            withDataFilePaths: dataFilePaths,
            success: { container in
                landingViewController.importProgressViewController.dismiss(animated: false, completion: nil)
                containerViewController?.reloadContainer()
            },
            failure: { error in
                landingViewController.importProgressViewController.dismiss(animated: false, completion: nil)
            }
        )
    }
    
    func createNewContainer(with url: URL, dataFilePaths: [String], startSigningWhenCreated: Bool = false, cleanUpDataFilesInDocumentsFolder: Bool = true) {
        let landingViewController = LandingViewController.shared!
    
        let filePath = url.relativePath
        let fileName = url.lastPathComponent
        
        let (filename, _) = fileName.filenameComponents()
        let containerFilename = filename + "." + DefaultNewContainerFormat
        var containerPath = MoppFileManager.shared.filePath(withFileName: containerFilename)
            containerPath = MoppFileManager.shared.duplicateFilename(atPath: containerPath)

        let navController = landingViewController.viewControllers[0] as! UINavigationController

        let cleanUpDataFilesInDocumentsFolderCode: () -> Void = {
            dataFilePaths.forEach {
                if $0.hasPrefix(MoppFileManager.shared.documentsDirectoryPath()) {
                    MoppFileManager.shared.removeFile(withPath: $0)
                }
            }
        }

        MoppLibContainerActions.sharedInstance().createContainer(
            withPath: containerPath,
            withDataFilePaths: dataFilePaths,
            success: { container in
                if cleanUpDataFilesInDocumentsFolder {
                    cleanUpDataFilesInDocumentsFolderCode()
                }
                if container == nil {
                
                    landingViewController.importProgressViewController.dismiss(animated: false, completion: nil)
                    
                    let alert = UIAlertController(title: L(.fileImportCreateNewFailedAlertTitle), message: L(.fileImportCreateNewFailedAlertMessage, [fileName]), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))

                    landingViewController.present(alert, animated: true)
                    return
                }
            
                landingViewController.importProgressViewController.dismiss(animated: false, completion: nil)
                landingViewController.selectedTab = .signTab
                
                let containerViewController = ContainerViewController.instantiate()
                containerViewController.containerPath = containerPath
                containerViewController.isCreated = true
                containerViewController.startSigningWhenOpened = startSigningWhenCreated
                
                navController.pushViewController(containerViewController, animated: true)
            
            }, failure: { error in
                if cleanUpDataFilesInDocumentsFolder {
                    cleanUpDataFilesInDocumentsFolderCode()
                }
                landingViewController.importProgressViewController.dismiss(animated: false, completion: nil)
                MoppFileManager.shared.removeFile(withPath: filePath)
            }
        )
    }
    
    func createLegacyContainer()
    {
        if let containerViewController = self as? ContainerViewController {
            let containerPath = containerViewController.containerPath!
            let containerPathURL = URL(fileURLWithPath: containerPath)
            createNewContainer(with: containerPathURL, dataFilePaths: [containerPath], startSigningWhenCreated: true, cleanUpDataFilesInDocumentsFolder: false)
        }
    }
}

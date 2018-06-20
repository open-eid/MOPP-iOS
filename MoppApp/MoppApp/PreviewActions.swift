//
//  PreviewActions.swift
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

protocol PreviewActions {
    func openFilePreview(dataFileFilename: String, containerFilePath: String, isShareButtonNeeded: Bool)
}

extension PreviewActions where Self: ContainerViewController {
    
    func openFilePreview(dataFileFilename: String, containerFilePath: String, isShareButtonNeeded: Bool) {
        
        let destinationPath = MoppFileManager.shared.tempFilePath(withFileName: dataFileFilename)

        let openAsicContainerPreview: (_ isPDF: Bool) -> Void = { [weak self] isPDF in
            let containerViewController = SigningContainerViewController.instantiate()
            
            containerViewController.sections = ContainerViewController.sectionsDefault
            containerViewController.isAsicContainer = true
            containerViewController.containerPath = destinationPath
            containerViewController.isForPreview = true
            containerViewController.forcePDFContentPreview = isPDF
            self?.navigationController?.pushViewController(containerViewController, animated: true)
        }
        
        let openCdocContainerPreview: () -> Void = { [weak self]  in
            let containerViewController = CryptoContainerViewController.instantiate()
            
            containerViewController.sections = ContainerViewController.sectionsEncrypted
            containerViewController.isContainerEncrypted = true
            containerViewController.isAsicContainer = false
            containerViewController.containerPath = destinationPath
            containerViewController.isForPreview = true
            self?.navigationController?.pushViewController(containerViewController, animated: true)
        }
        
        let openContentPreview: (_ filePath: String) -> Void = { [weak self] filePath in
            let dataFilePreviewViewController = UIStoryboard.container.instantiateViewController(of: DataFilePreviewViewController.self)
            dataFilePreviewViewController.isShareNeeded = isShareButtonNeeded
            dataFilePreviewViewController.previewFilePath = filePath
            self?.navigationController?.pushViewController(dataFilePreviewViewController, animated: true)
        }

        let openPDFPreview: () -> Void = { [weak self] in
            self?.updateState(.loading)
            MoppLibContainerActions.sharedInstance().openContainer(
                withPath: destinationPath,
                    success: { [weak self] (_ container: MoppLibContainer?) -> Void in
                        self?.updateState((self?.isCreated ?? false) ? .created : .opened)
                        if container == nil {
                            return
                        }
                        let signatureCount = container?.signatures.count ?? 0
                        if signatureCount > 0 && !(self?.forcePDFContentPreview ?? false) {
                            openAsicContainerPreview(true)
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
            if self.isAsicContainer {
                MoppLibContainerActions.sharedInstance().container(
                    containerFilePath,
                    saveDataFile: dataFileFilename,
                    to: destinationPath,
                    success: { [weak self] in
                        self?.notifications = []
                        self?.tableView.reloadData()
                        let (_, dataFileExt) = dataFileFilename.filenameComponents()
                        let isPDF = dataFileExt.lowercased() == ContainerFormatPDF
                        let forcePDFContentPreview = self?.forcePDFContentPreview ?? false

                        if dataFileExt.isAsicContainerExtension || (isPDF && !forcePDFContentPreview) {

                            // If container is PDF check signatures count with showing loading
                            if isPDF {
                                openPDFPreview()
                            } else {
                                openAsicContainerPreview(isPDF)
                            }
                        } else if dataFileExt.isCdocContainerExtension {
                            openCdocContainerPreview()
                        } else {
                            openContentPreview(destinationPath)
                        }

                    }, failure: { [weak self] error in
                        self?.errorAlert(message: error?.localizedDescription)
                })
            } else {
                self.notifications = []
                self.tableView.reloadData()
                let (_, dataFileExt) = dataFileFilename.filenameComponents()
                let isPDF = dataFileExt.lowercased() == ContainerFormatPDF
                
                if dataFileExt.isAsicContainerExtension || (isPDF && !self.forcePDFContentPreview ) {
                    
                    // If container is PDF check signatures count with showing loading
                    if isPDF {
                        openPDFPreview()
                    } else {
                        openAsicContainerPreview(isPDF)
                    }
                } else if dataFileExt.isCdocContainerExtension {
                    openCdocContainerPreview()
                } else {
                    openContentPreview(destinationPath)
                }
            }
        }
    }
}

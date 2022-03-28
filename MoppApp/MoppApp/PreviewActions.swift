//
//  PreviewActions.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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

        guard let destinationPath = MoppFileManager.shared.tempFilePath(withFileName: dataFileFilename) else {
            DispatchQueue.main.async { [weak self] in
                self?.errorAlert(message: L(.datafilePreviewFailed))
            }
            return
        }

        let openAsicContainerPreviewDocument: (_ containerViewController: ContainerViewController, _ isPDF: Bool, _ isSendingToSivaAgreed: Bool) -> Void = { [weak self] (containerViewController, isPDF, isSendingToSivaAgreed) in
            containerViewController.sections = ContainerViewController.sectionsDefault
            containerViewController.isAsicContainer = true
            containerViewController.containerPath = destinationPath
            containerViewController.isForPreview = true
            containerViewController.forcePDFContentPreview = isPDF
            containerViewController.isSendingToSivaAgreed = isSendingToSivaAgreed
            self?.navigationController?.pushViewController(containerViewController, animated: true)
        }

        let openAsicContainerPreview: (_ isPDF: Bool) -> Void = { isPDF in
            let containerViewController = SigningContainerViewController.instantiate()

            let destinationPathURL = URL(fileURLWithPath: destinationPath)
            if SiVaUtil.isDocumentSentToSiVa(fileUrl: destinationPathURL) {
                SiVaUtil.displaySendingToSiVaDialog { hasAgreed in
                    if (destinationPathURL.pathExtension == "ddoc" || destinationPathURL.pathExtension == "pdf") && !hasAgreed {
                        return
                    }
                    openAsicContainerPreviewDocument(containerViewController, isPDF, hasAgreed)
                }
            } else {
                openAsicContainerPreviewDocument(containerViewController, isPDF, true)
            }
        }

        let openCdocContainerPreview: () -> Void = { [weak self]  in
            let containerViewController = CryptoContainerViewController.instantiate()

            containerViewController.sections = ContainerViewController.sectionsEncrypted
            containerViewController.isContainerEncrypted = true
            containerViewController.isAsicContainer = false
            containerViewController.containerPath = destinationPath
            containerViewController.isDecrypted = false
            self?.navigationController?.pushViewController(containerViewController, animated: true)
        }

        let openContentPreviewDocument: (_ filePath: String) -> Void = { [weak self] filePath in
            let dataFilePreviewViewController = UIStoryboard.container.instantiateViewController(of: DataFilePreviewViewController.self)
            dataFilePreviewViewController.isShareNeeded = isShareButtonNeeded
            dataFilePreviewViewController.previewFilePath = filePath
            self?.navigationController?.pushViewController(dataFilePreviewViewController, animated: true)
        }

        let openContentPreview: (_ filePath: String) -> Void = { [weak self] filePath in
            guard MoppFileManager.shared.fileExists(filePath) else {
                printLog("File does not exist. Unable to open file for preview")
                self?.errorAlert(message: L(.datafilePreviewFailed))
                return
            }

            let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()

            if fileExtension != "pdf" && SiVaUtil.isDocumentSentToSiVa(fileUrl: URL(fileURLWithPath: filePath)) {
                SiVaUtil.displaySendingToSiVaDialog { hasAgreed in
                    if hasAgreed {
                        openContentPreviewDocument(filePath)
                    }
                }
            } else {
                openContentPreviewDocument(filePath)
            }

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
                        self?.updateState((self?.isCreated ?? false) ? .created : .opened)
                        if let nsError = error as NSError?, nsError.code == 10018 {
                            self?.errorAlert(message: L(.noConnectionMessage))
                            return
                        }
                        self?.errorAlert(message: error?.localizedDescription)
                        return
                    })
        }

        if self.isAsicContainer {
            guard MoppFileManager.shared.fileExists(containerFilePath) else {
                printLog("Container does not exist. Unable to open file for preview")
                self.errorAlert(message: L(.datafilePreviewFailed))
                return
            }
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

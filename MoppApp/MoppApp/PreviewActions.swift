//
//  PreviewActions.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
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
                self?.infoAlert(message: L(.datafilePreviewFailed))
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

            let duplicateFilesInContainer = MimeTypeExtractor.findDuplicateFilenames(in: destinationPathURL)
            if !duplicateFilesInContainer.isEmpty {
                self.infoAlert(message: L(.fileImportFailedDuplicateFiles, duplicateFilesInContainer))
                return
            }

            SiVaUtil.setIsSentToSiva(isSent: false)
            if (SiVaUtil.isDocumentSentToSiVa(fileUrl: destinationPathURL) && !MimeTypeExtractor.isXadesContainer(filePath: destinationPathURL)) {
                SiVaUtil.displaySendingToSiVaDialog { hasAgreed in
                    if (destinationPathURL.pathExtension == "ddoc" || destinationPathURL.pathExtension == "pdf") && !hasAgreed {
                        self.updateState(.opened)
                        return
                    }
                    openAsicContainerPreviewDocument(containerViewController, isPDF, hasAgreed)
                }
            } else {
                SiVaUtil.setIsSentToSiva(isSent: true)
                openAsicContainerPreviewDocument(containerViewController, isPDF, true)
            }
        }

        let openCdocContainerPreview: () -> Void = { [weak self]  in
            let containerViewController = CryptoContainerViewController.instantiate()

            containerViewController.sections = ContainerViewController.sectionsEncrypted
            containerViewController.isContainerEncrypted = true
            containerViewController.isAsicContainer = false
            containerViewController.isForPreview = true
            containerViewController.containerPath = destinationPath
            containerViewController.isDecrypted = false
            self?.navigationController?.pushViewController(containerViewController, animated: true)
        }

        let openContentPreviewDocument: (_ filePath: String) -> Void = { [weak self] filePath in
            let dataFilePreviewViewController = UIStoryboard.container.instantiateViewController(of: DataFilePreviewViewController.self)
            dataFilePreviewViewController.modalPresentationStyle = .overFullScreen
            dataFilePreviewViewController.isShareNeeded = isShareButtonNeeded
            dataFilePreviewViewController.previewFilePath = filePath
            self?.navigationController?.pushViewController(dataFilePreviewViewController, animated: false)
        }

        let openContentPreview: (_ filePath: String) -> Void = { [weak self] filePath in
            guard MoppFileManager.shared.fileExists(filePath) else {
                printLog("File does not exist. Unable to open file for preview")
                self?.infoAlert(message: L(.datafilePreviewFailed))
                return
            }
            
            let url = URL(fileURLWithPath: filePath)

            let urlResourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey])
            if let isDirectory = urlResourceValues?.isDirectory, isDirectory {
                self?.infoAlert(message: L(.datafilePreviewNotAvailable))
                return
            }

            let fileExtension = url.pathExtension.lowercased()

            SiVaUtil.setIsSentToSiva(isSent: false)
            if (fileExtension != "pdf" && SiVaUtil.isDocumentSentToSiVa(fileUrl: URL(fileURLWithPath: filePath)) && !MimeTypeExtractor.isXadesContainer(filePath: url)) {
                SiVaUtil.displaySendingToSiVaDialog { hasAgreed in
                    if hasAgreed {
                        openContentPreviewDocument(filePath)
                    }
                }
            } else {
                SiVaUtil.setIsSentToSiva(isSent: true)
                openContentPreviewDocument(filePath)
            }

        }

        let openPDFPreview: () -> Void = { [weak self] in
            self?.updateState(.loading)
            SiVaUtil.setIsSentToSiva(isSent: false)
            let fileURL = URL(fileURLWithPath: destinationPath)
            let isSignedPDF = SiVaUtil.isSignedPDF(url: fileURL as CFURL)
            if !isSignedPDF {
                openContentPreview(destinationPath)
                return
            }
            
            openAsicContainerPreview(true)
        }

        if self.isAsicContainer {
            guard MoppFileManager.shared.fileExists(containerFilePath) else {
                printLog("Container does not exist. Unable to open file for preview")
                self.infoAlert(message: L(.datafilePreviewFailed))
                return
            }
        }

        // If current container is PDF opened as a container preview then open it as a content preview which
        // is same as opening it's data file (which is a reference to itself) as a content preview
        if forcePDFContentPreview {
            openContentPreview(containerPath)
        } else {
            if self.isAsicContainer {
                MoppLibContainerActions.container(containerFilePath, saveDataFile: dataFileFilename, to: destinationPath) { [weak self] error in
                    if let error {
                        self?.infoAlert(message: error.localizedDescription)
                        return
                    }
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
                }
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

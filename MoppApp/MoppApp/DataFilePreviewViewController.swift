//
//  DataFilePreviewViewController.swift
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
import QuickLook

class DataFilePreviewViewController : MoppViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {

    var previewFilePath: String!
    var isShareNeeded = false
    
    let quickLookController = QLPreviewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        quickLookController.dataSource = self
        quickLookController.delegate = self
        
        quickLookController.modalPresentationStyle = .overFullScreen
        
        printLog("Showing preview for file: \(FileUtil.addDefaultExtension(url: getFileUrl(filePath: previewFilePath)).lastPathComponent)")
        present(quickLookController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let url = getFileUrl(filePath: previewFilePath)
        if isShareNeeded {
            setupNavigationItemForPushedViewController(title: url.lastPathComponent, filePath: previewFilePath)
        } else {
            setupNavigationItemForPushedViewController(title: url.lastPathComponent)
        }
        LandingViewController.shared.presentButtons([])
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let url = getFileUrl(filePath: previewFilePath)
        if url.pathExtension.isEmpty {
            let urlWithDefaultExtension = FileUtil.addDefaultExtension(url: getFileUrl(filePath: previewFilePath))
            let urlPath = MoppFileManager.shared.copyFile(withPath: url.path, toPath: urlWithDefaultExtension.path)
            return URL(fileURLWithPath: urlPath) as QLPreviewItem
        }
        return url as QLPreviewItem
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        printLog("Dismissing preview controller")
        self.navigationController?.popViewController(animated: false)
    }
    
    private func getFileUrl(filePath: String) -> URL {
        return URL(fileURLWithPath: filePath)
    }
}

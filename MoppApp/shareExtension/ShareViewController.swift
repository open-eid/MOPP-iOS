//
//  ShareViewController.m
//  shareExtension
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
import UIKit

class ShareViewController : UIViewController, URLSessionDelegate
{
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSObject.performSelector(inBackground: #selector(self.cacheFiles), with: {(_ imported: Bool) -> Void in
            if imported {
                self.performSelector(onMainThread: #selector(self.displayFilesImportedMessage), with: nil, waitUntilDone: false)
            }
        })
    }

    func displayFilesImportedMessage() {
        let alert = UIAlertController(title: NSLocalizedString("share-extension-import-title", comment: ""), message: NSLocalizedString("share-extension-import-message", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            extensionContext.completeRequest(returningItems: [], completionHandler: nil)
        }))
        present(alert, animated: true) { _ in }
    }

    func cacheFiles(withCompletion completion: @escaping ((_ imported:Bool) -> Void)) {
        let array = extensionContext.inputItems
        cacheItem(0, withProvider: 0, inArray: array, completion: completion)
    }

    func cacheItem(_ itemIndex: Int, withProvider providerIndex: Int, inArray items: [Any], completion: @escaping (_ imported:Bool) -> Void) {
        if items.count > itemIndex {
            let item = items[itemIndex] as? NSExtensionItem
            if item.attachments?.count > providerIndex {
                cacheFile(forProvider: item.attachments[providerIndex], completion: {(_ imported: Bool) -> Void in
                    self.cacheItem(itemIndex, withProvider: providerIndex + 1, inArray: items, completion: completion)
                })
            }
            else {
                cacheItem(itemIndex + 1, withProvider: 0, inArray: items, completion: completion)
            }
        }
        else {
            completion(true)
        }
    }

    func cacheFile(for provider: NSItemProvider, completion: @escaping (_ imported:Bool) -> Void) {
        if provider.hasItemConformingToTypeIdentifier("public.data") {
            provider.loadItem(forTypeIdentifier: "public.data", options: nil, completionHandler: {(_ item: NSSecureCoding?, _ error: Error?) -> Void in
                if ((item as? NSObject) is URL) {
                    let itemUrl = item as? URL
                    completion(self.cacheFile(on: itemUrl))
                }
            })
        }
    }

    func cacheFile(on itemUrl: URL) -> Bool {
        if (itemUrl.scheme == "file") {
            let data = Data(contentsOf: itemUrl)
            if data != nil {
                var groupFolderUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ee.ria.digidoc.ios")
                groupFolderUrl = groupFolderUrl?.appendingPathComponent("Temp")
                var err: Error?
                try? FileManager.default.createDirectory(at: groupFolderUrl!, withIntermediateDirectories: false, attributes: nil)
                let filePath: URL? = groupFolderUrl?.appendingPathComponent((itemUrl.lastPathComponent)!)
                var error: Error?
                try? FileManager.default.copyItem(at: itemUrl, to: filePath!)
                if error == nil {
                    return true
                }
            }
        }
        else {
            let conf = URLSessionConfiguration.background(withIdentifier: "digidoc.share.background.task")
            conf.sharedContainerIdentifier = "group.ee.ria.digidoc.ios"
            let session = URLSession(configuration: conf, delegate: self, delegateQueue: nil)
            let task: URLSessionDownloadTask? = session.downloadTask(with: itemUrl)
            task?.resume()
            return true
        }
        return false
    }

}

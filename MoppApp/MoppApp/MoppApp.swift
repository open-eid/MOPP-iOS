//
//  MoppApp.swift
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

import Foundation
import FirebaseCrashlytics
import Firebase

class MoppApp: UIApplication, URLSessionDelegate, URLSessionDownloadDelegate {

    static let instance = UIApplication.shared as! MoppApp

    var landingViewController: LandingViewController?
    var tempUrl: URL?
    var downloadCompletion: (() -> Void)? = nil
    var window: UIWindow?
    var currentElement:String = ""
    var documentFormat:String = ""
    var downloadTask: URLSessionTask?
    var isInvalidFileInList: Bool = false

    var rootViewController: UIViewController? {
        return window?.rootViewController
    }

    // Instantiated here for preloading webview content
    var aboutViewController: AboutViewController = {
        let aboutViewController = UIStoryboard.settings.instantiateViewController(of: AboutViewController.self)
            aboutViewController.modalPresentationStyle = .overFullScreen
        return aboutViewController
    }()

    enum Nib : String {
        case containerElements = "ContainerElements"
        case recentContainersElements = "RecentContainersElements"
        case customElements = "CustomElements"
        case signingElements = "SigningElements"
    }
    var nibs: [Nib: UINib] = [:]

    enum FileImportIntent {
        case openOrCreate
        case addToContainer
    }

    enum ContainerType {
        case asic
        case cdoc
    }

    static var versionString:String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? String()
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? String()
        return "\(version).\(build)"
    }

    static var iosVersion:String {
        let majorVersion = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        let minorVersion = ProcessInfo.processInfo.operatingSystemVersion.minorVersion
        let patchVersion = ProcessInfo.processInfo.operatingSystemVersion.patchVersion
        return "\(majorVersion).\(minorVersion).\(patchVersion)"
    }

    func didFinishLaunchingWithOptions(launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Log console logs to a file in Documents folder
        #if DEBUG
            setDebugMode(value: true)

            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory: String = paths[0]
            let currentDate = MoppDateFormatter().ddMMYYYY(toString: Date())
            let fileName = "\(currentDate).log"
            let logFilePath = URL(string: documentsDirectory)?.appendingPathComponent(fileName)
            freopen(logFilePath!.absoluteString, "a+", stderr)
        #else
            setDebugMode(value: false)
        #endif


        loadNibs()
        // Set navBar not translucent by default.

        FirebaseApp.configure()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.white

        // Check for min Xcode 11 and iOS 13
        #if compiler(>=5.1)
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }
        #endif

        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().tintColor = UIColor.moppText
        UINavigationBar.appearance().barTintColor = UIColor.moppBaseBackground
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor : UIColor.moppText]
        UINavigationBar.appearance().barStyle = .default

        // Selected TabBar item text color
        UITabBarItem.appearance().setTitleTextAttributes(
            [.foregroundColor:UIColor.white,
             .font:UIFont(name: "RobotoCondensed-Regular", size: 10)!],
            for: .selected)

        // Unselected TabBar item text color
        UITabBarItem.appearance().setTitleTextAttributes(
            [.foregroundColor:UIColor.moppUnselectedTabBarItem,
             .font:UIFont(name: "RobotoCondensed-Regular", size: 10)!],
            for: .normal)

        if isDeviceJailbroken {
            window?.rootViewController = UIStoryboard.jailbreak.instantiateInitialViewController()
        } else {
            
            #if !DEBUG
                // Prevent screen recording
                NotificationCenter.default.addObserver(self, selector: #selector(handleScreenRecording), name: UIScreen.capturedDidChangeNotification, object: nil)

                // Give time to load before handling screen recording
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.handleScreenRecording()
                }
            #endif

            // Get remote configuration
            SettingsConfiguration().getCentralConfiguration()

            TSLUpdater().checkForTSLUpdates()

            let notification = Notification(name: .configurationLoaded)
            NotificationCenter.default.post(notification)

            let initializationViewController = InitializationViewController()
            window?.rootViewController = initializationViewController
        }

        window?.makeKeyAndVisible()
        return true
    }

    func handleSharedFiles(sharedFiles: [URL]) {
        if !sharedFiles.isEmpty {
            _ = openPath(urls: sharedFiles)
        }
    }

    func setupTabController() {
        landingViewController = UIStoryboard.landing.instantiateInitialViewController(of: LandingViewController.self)
        window?.rootViewController = landingViewController

        let sharedFiles: [URL] = MoppFileManager.shared.sharedDocumentPaths().compactMap { URL(fileURLWithPath: $0) }
        if !sharedFiles.isEmpty {
           handleSharedFiles(sharedFiles: sharedFiles)
        } else {
            if let tempUrl = self.tempUrl {
                _ = openUrl(url: tempUrl, options: [:])
                self.tempUrl = nil
            }
        }
        if Crashlytics.crashlytics().didCrashDuringPreviousExecution() {
            if (DefaultsHelper.crashReportSetting != CrashlyticsAlwaysSend) {
                displayCrashReportDialog()
            } else {
                self.checkForUnsentReportsWithCompletion(send: true)
            }
        }
    }

    func displayCrashReportDialog() {
        let alert = UIAlertController(title: L(.crashlyticsTitle), message: L(.crashlyticsMessage), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L(.crashlyticsActionSend), style: .default, handler: { (_ action: UIAlertAction) in
            self.checkForUnsentReportsWithCompletion(send: true)
        }))
        alert.addAction(UIAlertAction(title: L(.crashlyticsActionAlwaysSend), style: .default, handler: {(_ action: UIAlertAction) -> Void in
            DefaultsHelper.crashReportSetting = CrashlyticsAlwaysSend
            self.checkForUnsentReportsWithCompletion(send: true)
        }))
        alert.addAction(UIAlertAction(title: L(.crashlyticsActionDoNotSend), style: .cancel, handler: {(_ action: UIAlertAction) -> Void in
            self.checkForUnsentReportsWithCompletion(send: false)
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
    }

    func checkForUnsentReportsWithCompletion(send: Bool) {
        Crashlytics.crashlytics().checkForUnsentReports { hasUnsentReport in
            if ((send && hasUnsentReport)) {
                Crashlytics.crashlytics().sendUnsentReports()
            } else {
                Crashlytics.crashlytics().deleteUnsentReports()
            }
        }
    }

    func openUrl(url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return openPath(urls: [url], options: options)
    }

    func openPath(urls: [URL], options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard !urls.isEmpty else {
            NSLog("No URLs found to open")
            return false
        }
        var fileUrls: [URL] = []
        var cleanup: Bool = false
        for url in urls {
            if !url.absoluteString.isEmpty {
                
                guard let keyWindow = UIApplication.shared.keyWindow, let topViewController = keyWindow.rootViewController?.getTopViewController() else {
                    NSLog("Unable to get view controller")
                    return false
                }
                
                var fileUrl: URL = url
                
                // Handle file from web with "digidoc" scheme
                if url.scheme == "digidoc" && url.host == "http" {
                    NSLog("Opening HTTP links is not supported")
                    DispatchQueue.main.async {
                        return topViewController.showErrorMessage(title: L(.errorAlertTitleGeneral), message: L(.fileImportNewFileOpeningFailedAlertMessage, [url.lastPathComponent]))
                    }
                    return false
                } else if url.scheme == "digidoc" {
                    let dispatchGroup: DispatchGroup = DispatchGroup()
                    dispatchGroup.enter()
                    UrlSchemeHandler.shared.getFileLocationFromURL(url: url) { (fileLocation: URL?) in
                        guard let filePath = fileLocation else {
                            NSLog("Unable to get file location from URL")
                            DispatchQueue.main.async {
                                return topViewController.showErrorMessage(title: L(.errorAlertTitleGeneral), message: L(.fileImportNewFileOpeningFailedAlertMessage, [url.lastPathComponent]))
                            }
                            dispatchGroup.leave()
                            return
                        }
                        fileUrl = filePath
                        dispatchGroup.leave()
                    }
                    // Wait until downloading file from web is done
                    dispatchGroup.wait()
                }

                // Check if url has changed after opening file with digidoc scheme to prevent multiple error messages
                if fileUrl.scheme == "digidoc" && fileUrl == url {
                    NSLog("Failed to open file with scheme")
                    return false
                }

                // Used to access folders on user device when opening container outside app (otherwise gives "Operation not permitted" error)
                fileUrl.startAccessingSecurityScopedResource()

                // Let all the modal view controllers know that they should dismiss themselves
                NotificationCenter.default.post(name: .didOpenUrlNotificationName, object: nil)

                // When app has just been launched, it may not be ready to deal with containers yet. We need to wait until libdigidocpp setup is complete.
                if landingViewController == nil {
                    tempUrl = fileUrl
                    return true
                }
                
                let isResourceReachable = try? fileUrl.checkResourceIsReachable()
                if fileUrl.isFileURL && (isResourceReachable == nil || isResourceReachable == false) {
                    let dispatchGroup: DispatchGroup = DispatchGroup()
                    dispatchGroup.enter()
                    FileDownloader.shared.downloadExternalFile(url: fileUrl) { fileLocation in
                        if let fileLocation = fileLocation {
                            fileUrl = fileLocation
                        }
                        dispatchGroup.leave()
                    }
                    dispatchGroup.wait()
                }

                var newUrl: URL = fileUrl
                
                let isFileEmpty = MoppFileManager.isFileEmpty(fileUrl: newUrl)
                
                if isFileEmpty {
                    NSLog("Unable to import empty file")
                    if urls.count == 1 {
                        topViewController.showErrorMessage(title: L(.errorAlertTitleGeneral), message: L(.fileImportFailedEmptyFile))
                        return false
                    }
                    isInvalidFileInList = true
                }

                // Sharing from Google Drive may change file extension
                let fileExtension: String? = MimeTypeExtractor.determineFileExtension(mimeType: MimeTypeExtractor.getMimeTypeFromContainer(filePath: newUrl)) ?? newUrl.pathExtension

                guard var pathExtension = fileExtension else {
                    NSLog("Unable to get file extension")
                    topViewController.showErrorMessage(title: L(.errorAlertTitleGeneral), message: L(.fileImportNewFileOpeningFailedAlertMessage, [newUrl.lastPathComponent]))
                    return false
                }
                
                // Some containers have the same mimetype
                pathExtension = MimeTypeExtractor.determineContainer(mimetype: MimeTypeExtractor.getMimeTypeFromContainer(filePath: newUrl), fileExtension: newUrl.pathExtension)

                do {
                    let newData: Data? = try Data(contentsOf: newUrl)
                    let fileName: String = MoppLibManager.sanitize(newUrl.deletingPathExtension().lastPathComponent)
                    let tempDirectoryPath: String? = MoppFileManager.shared.tempDocumentsDirectoryPath()
                    guard let tempDirectory = tempDirectoryPath else {
                        NSLog("Unable to get temporary file directory")
                        topViewController.showErrorMessage(title: L(.errorAlertTitleGeneral), message: L(.fileImportNewFileOpeningFailedAlertMessage, ["\(fileName).\(pathExtension)"]))
                        return false
                    }
                    let fileURL: URL? = URL(fileURLWithPath: tempDirectory, isDirectory: true).appendingPathComponent(fileName, isDirectory: false).appendingPathExtension(pathExtension)

                    guard let newUrlData: Data = newData, let filePath: URL = fileURL else {
                        NSLog("Unable to get file data or file path")
                        topViewController.showErrorMessage(title: L(.errorAlertTitleGeneral), message: L(.fileImportNewFileOpeningFailedAlertMessage, ["\(fileName).\(pathExtension)"]))
                        return false
                    }
                    do {
                        try newUrlData.write(to: filePath, options: .atomic)
                        newUrl = filePath
                        if !isFileEmpty {
                            fileUrls.append(newUrl)
                        }
                        cleanup = true
                    } catch let error {
                        NSLog("Error writing to file: \(error.localizedDescription)")
                        topViewController.showErrorMessage(title: L(.fileImportOpenExistingFailedAlertTitle), message: L(.fileImportNewFileOpeningFailedAlertMessage, ["\(fileName).\(pathExtension)"]))
                        return false
                    }
                } catch let error {
                    NSLog("Error getting directory: \(error)")
                    topViewController.showErrorMessage(title: L(.fileImportOpenExistingFailedAlertTitle), message: L(.fileImportNewFileOpeningFailedAlertMessage, [newUrl.lastPathComponent]))
                    return false
                }


                var isXmlExtensionFileCdoc = false
                if newUrl.pathExtension.isXmlFileExtension {
                    //Google Drive will change file extension and puts it to Inbox folder
                    if newUrl.absoluteString.range(of: "/Inbox/") != nil {
                        newUrl = URL (string: newUrl.absoluteString.replacingOccurrences(of: "/Inbox", with: "/temp"))!
                        isXmlExtensionFileCdoc = self.isXmlExtensionFileCdoc(with: url)
                        if isXmlExtensionFileCdoc {
                            newUrl.deletePathExtension()
                            newUrl.appendPathExtension(ContainerFormatCdoc)
                        }
                        let isFileMoved = MoppFileManager.shared.moveFile(withPath: url.path, toPath: newUrl.path, overwrite: true)
                        if !isFileMoved {
                            newUrl = url
                            fileUrls.append(newUrl)
                        }
                    }
                }

                if newUrl.pathExtension.isCdocContainerExtension {
                    landingViewController?.containerType = .cdoc
                } else {
                    landingViewController?.containerType = .asic
                }
            }
            url.stopAccessingSecurityScopedResource()
        }

        if fileUrls.isEmpty {
            if isInvalidFileInList {
                landingViewController?.showErrorMessage(title: L(.errorAlertTitleGeneral), message: L(.fileImportFailedEmptyFile))
                return false
            }
            fileUrls = urls
        }

        landingViewController?.fileImportIntent = .openOrCreate
        landingViewController?.importFiles(with: fileUrls, cleanup: cleanup, isEmptyFileImported: isInvalidFileInList)

        return true
    }

    func willResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        #if !DEBUG
            ScreenDisguise.shared.show()
        #endif
    }

    func didEnterBackground() {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        MoppFileManager.shared.removeFilesFromSharedFolder()
    }


    func willEnterForeground() {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        #if !DEBUG
            ScreenDisguise.shared.hide()
        #endif
    }

    func didBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        #if !DEBUG
            ScreenDisguise.shared.hide()
        #endif

        if UIViewController().getTopViewController() is InitializationViewController || UIViewController().getTopViewController() is LandingViewController {
            let sharedFiles: [URL] = MoppFileManager.shared.sharedDocumentPaths().compactMap { URL(fileURLWithPath: $0) }
            if !sharedFiles.isEmpty {
               handleSharedFiles(sharedFiles: sharedFiles)
            }
        }

        restartIdCardDiscovering()
    }

    func willTerminate() {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

        // Remove temporarily saved files folder
        MoppFileManager.shared.removeTempSavedFilesInDocuments(folderName: "Saved Files")
        MoppFileManager.shared.removeTempSavedFilesInDocuments(folderName: "Downloads")
        MoppFileManager.shared.removeFilesFromSharedFolder()
    }

    func handleEventsForBackgroundURLSession(identifier: String, completionHandler: @escaping () -> Void) {
        downloadCompletion = completionHandler
        let conf = URLSessionConfiguration.background(withIdentifier: identifier)
        let session = URLSession(configuration: conf, delegate: self, delegateQueue: nil)
        session.getTasksWithCompletionHandler({(_ dataTasks: [URLSessionDataTask], _ uploadTasks: [URLSessionUploadTask], _ downloadTasks: [URLSessionDownloadTask]) -> Void in
        })
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let data = try? Data(contentsOf: location)
        if data != nil {
            let groupFolderUrl = MoppFileManager.shared.fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.ee.ria.digidoc.ios")
            guard var tempGroupFolderUrl = groupFolderUrl else {
                NSLog("Unable to get temp group folder url")
                return
            }
            tempGroupFolderUrl = tempGroupFolderUrl.appendingPathComponent("Temp")
            try? MoppFileManager.shared.fileManager.createDirectory(at: tempGroupFolderUrl, withIntermediateDirectories: false, attributes: nil)
            let filePath: URL? = tempGroupFolderUrl.appendingPathComponent(location.lastPathComponent)
            guard let tempFilePath = filePath else {
                NSLog("Unable to get temp file path url")
                return
            }
            try? MoppFileManager.shared.fileManager.copyItem(at: location, to: tempFilePath)
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async(execute: { [weak self] () -> Void in
            self?.downloadCompletion?()
        })
    }

    func resetRootViewController() {
        landingViewController = UIStoryboard.landing.instantiateInitialViewController(of: LandingViewController.self)
        window?.rootViewController = landingViewController
        window?.makeKeyAndVisible()
    }

    func isXmlExtensionFileCdoc(with url: URL) -> Bool {
        let parser = XMLParser(contentsOf: url)
        parser?.delegate = self;
        parser?.parse()
        if documentFormat.hasPrefix("ENCDOC-XML|1.") {
            documentFormat = ""
            return true
        }
        return false
    }

    func convertViewToImage(with view: UIView) -> UIImage? {

        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            view.layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }
        return nil
    }
    
    @objc private func handleScreenRecording() -> Void {
        ScreenDisguise.shared.handleScreenRecordingPrevention()
    }

    private func restartIdCardDiscovering() {
        let topViewController = UIViewController().getTopViewController()

        for childViewController in topViewController.children {
            if childViewController is IdCardViewController {
                MoppLibCardReaderManager.sharedInstance().startDiscoveringReaders()
            }
        }
    }

    private func setDebugMode(value: Bool) -> Void {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: "isDebugMode")
        defaults.synchronize()
    }

    private func showErrorMessage(title: String, message: String) {
        guard let keyWindow = UIApplication.shared.keyWindow, let topViewController = keyWindow.rootViewController?.getTopViewController() else {
            return
        }
        topViewController.errorAlert(message: message, title: title, dismissCallback: nil)
    }
}

extension MoppApp {
    func loadNibs() {
        nibs[.containerElements] = UINib(nibName: Nib.containerElements.rawValue, bundle: Bundle.main)
        nibs[.recentContainersElements] = UINib(nibName: Nib.recentContainersElements.rawValue, bundle: Bundle.main)
        nibs[.customElements] = UINib(nibName: Nib.customElements.rawValue, bundle: Bundle.main)
        nibs[.signingElements] = UINib(nibName: Nib.signingElements.rawValue, bundle: Bundle.main)
    }
}

//
//  MoppApp.swift
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
    
    // iOS 11 blur window fix
    var blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
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

    func didFinishLaunchingWithOptions(launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
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

    func setupTabController() {
        landingViewController = UIStoryboard.landing.instantiateInitialViewController(of: LandingViewController.self)
        window?.rootViewController = landingViewController
        if let tempUrl = self.tempUrl {
            _ = openUrl(url: tempUrl, options: [:])
            self.tempUrl = nil
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

    func openUrl(url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if !url.absoluteString.isEmpty {
            
            // Used to access folders on user device when opening container outside app (otherwise gives "Operation not permitted" error)
            url.startAccessingSecurityScopedResource()
        
            // Let all the modal view controllers know that they should dismiss themselves
            NotificationCenter.default.post(name: .didOpenUrlNotificationName, object: nil)
        
            // When app has just been launched, it may not be ready to deal with containers yet. We need to wait until libdigidocpp setup is complete.
            if landingViewController == nil {
                tempUrl = url
                return true
            }
            
            var newUrl = url
            
            // Sharing from Google Drive may change file extension
            let fileExtension = determineFileExtension(mimeType: determineMimeType(url: newUrl))
            do {
                let tempFileData: Data = try Data(contentsOf: newUrl)
                let tempFileExtension = fileExtension == "" ? newUrl.pathExtension : fileExtension;
                let tempFileName: String = newUrl.deletingPathExtension().lastPathComponent
                let tempFileURL: URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("temp", isDirectory: true).appendingPathComponent("\(tempFileName).\(tempFileExtension)")
                do {
                    try tempFileData.write(to: tempFileURL, options: .atomic)
                    newUrl = tempFileURL
                } catch {
                    MSLog("Error writing to file: \(error)")
                }
            } catch {
                MSLog("Error getting directory: \(error)")
            }

            var isXmlExtensionFileCdoc = false
            if newUrl.pathExtension.isXmlFileExtension {
                //Google Drive will change file extension and puts it to Inbox folder
                if newUrl.absoluteString.range(of: "/Inbox/") != nil {
                    newUrl = URL (string: newUrl.absoluteString.replacingOccurrences(of: "/Inbox", with: "/temp"))!
                    isXmlExtensionFileCdoc = self.isXmlExtensionFileCdoc(with: url)
                    if isXmlExtensionFileCdoc {
                        newUrl.deletePathExtension()
                        newUrl.appendPathExtension("cdoc")
                    }
                    let isFileMoved = MoppFileManager.shared.moveFile(withPath: url.path, toPath: newUrl.path, overwrite: true)
                    if !isFileMoved {
                        newUrl = url
                    }
                }
            }
            
            if newUrl.pathExtension.isCdocContainerExtension {
                landingViewController?.containerType = .cdoc
            } else {
                landingViewController?.containerType = .asic
            }
            landingViewController?.fileImportIntent = .openOrCreate
            landingViewController?.importFiles(with: [newUrl])
        }
        url.stopAccessingSecurityScopedResource()
        return true
    }

    func willResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        #if !DEBUG
            if #available(iOS 12, *) {
                ScreenDisguise.shared.show()
            } else {
                // iOS 11 blur window fix
                blurWindow()
            }
        #endif
    }

    func didEnterBackground() {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }


    func willEnterForeground() {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        #if !DEBUG
            if #available(iOS 12, *) {
                    ScreenDisguise.shared.hide()
            } else {
                // iOS 11 blur window fix
                blurWindow()
                removeWindowBlur()
            }
        #endif
    }

    func didBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        #if !DEBUG
            if #available(iOS 12, *) {
                ScreenDisguise.shared.hide()
            } else {
                // iOS 11 blur window fix
                removeWindowBlur()
            }
        #endif
        
        restartIdCardDiscovering()
    }

    func willTerminate() {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        removeSignatureOnAppClose()
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
            var groupFolderUrl = MoppFileManager.shared.fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.ee.ria.digidoc.ios")
            groupFolderUrl = groupFolderUrl?.appendingPathComponent("Temp")
            var err: Error?
            try? MoppFileManager.shared.fileManager.createDirectory(at: groupFolderUrl!, withIntermediateDirectories: false, attributes: nil)
            let filePath: URL? = groupFolderUrl?.appendingPathComponent(location.lastPathComponent)
            var error: Error?
            try? MoppFileManager.shared.fileManager.copyItem(at: location, to: filePath!)
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
    
    private func blurWindow() -> Void {
        self.window?.backgroundColor = .white
        window?.alpha = 0.5
        blurEffectView.frame = self.window!.bounds
        self.window?.addSubview(blurEffectView)
    }
    
    private func removeWindowBlur() -> Void {
        if blurEffectView.isDescendant(of: self.window!) {
            blurEffectView.backgroundColor = .clear
            window?.alpha = 1.0
            blurEffectView.removeFromSuperview()
        }
    }
    
    private func restartIdCardDiscovering() {
        let topViewController = UIViewController().getTopViewController()
        
        for childViewController in topViewController.childViewControllers {
            if childViewController is IdCardViewController {
                MoppLibCardReaderManager.sharedInstance().startDiscoveringReaders()
            }
        }
    }
    
    private func determineMimeType(url: URL) -> String {
        do {
            let fileData = try Data(contentsOf: url)
            let fileDataAscii = String(data: fileData, encoding: .ascii)
            
            var isDdoc: Bool = false
            
            MimeTypeDecoder().getMimeType(fileString: fileDataAscii ?? "") { (containerExtension) in
                if containerExtension == "ddoc" {
                    isDdoc = true
                }
            }
            
            if isDdoc {
                return "application/x-ddoc"
            }
            
            return MimeTypeExtractor().getMimeTypeFromContainer(filePath: url)
            
        } catch {
            MSLog("Error getting url data \(error)")
        }
        
        return "application/octet-stream"
    }
    
    private func determineFileExtension(mimeType: String) -> String {
        switch mimeType {
        case "application/vnd.etsi.asic-e+zip":
            return "asice"
        case "application/vnd.etsi.asic-s+zip":
            return "asics"
        case "application/x-ddoc":
            return "ddoc"
        case "application/x-cdoc":
            return "cdoc"
        default:
            return ""
        }
    }
    
    private func setDebugMode(value: Bool) -> Void {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: "isDebugMode")
        defaults.synchronize()
    }
    
    private func removeSignatureOnAppClose() {
        let topViewController = UIViewController().getTopViewController()
        
        if topViewController is MobileIDChallengeViewController || topViewController is SmartIDChallengeViewController {
            MoppLibManager.cancelSigning()
        }
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

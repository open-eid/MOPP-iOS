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
import Crashlytics
import Fabric


class MoppApp: UIApplication, CrashlyticsDelegate, URLSessionDelegate, URLSessionDownloadDelegate {

    static let instance = UIApplication.shared as! MoppApp

    var landingViewController: LandingViewController?
    var tempUrl: URL?
    var crashReportCompletion: ((_ submit: Bool) -> Void)? = nil
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
        loadNibs()
        // Set navBar not translucent by default.
        Crashlytics.sharedInstance().delegate = self
        Fabric.with([Crashlytics.self])
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
            
            MoppLibManager().checkVersionUpdateAndMissingFiles(FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0])
            
            // Get remote configuration
            SettingsConfiguration().getCentralConfiguration()
            
            let notification = Notification(name: .configurationLoaded)
            NotificationCenter.default.post(notification)
            
            let initializationViewController = InitializationViewController()
            window?.rootViewController = initializationViewController
        }

        window?.makeKeyAndVisible()
        return true
    }

    func crashlyticsDidDetectReport(forLastExecution report: CLSReport, completionHandler: @escaping (_ submit: Bool) -> Void) {
        if DefaultsHelper.crashReportSetting == CrashlyticsAlwaysSend {
            completionHandler(true)
        }
        else {
            crashReportCompletion = completionHandler
        }
    }

    func setupTabController() {
        landingViewController = UIStoryboard.landing.instantiateInitialViewController(of: LandingViewController.self)
        window?.rootViewController = landingViewController
        if let tempUrl = self.tempUrl {
            _ = openUrl(url: tempUrl, options: [:])
            self.tempUrl = nil
        }
        if crashReportCompletion != nil {
            displayCrashReportDialog()
        }
    }

    func displayCrashReportDialog() {
        let alert = UIAlertController(title: L(.crashlyticsTitle), message: L(.crashlyticsMessage), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L(.crashlyticsActionSend), style: .default, handler: { (_ action: UIAlertAction) in
            self.crashReportCompletion?(true)
            self.crashReportCompletion = nil
        }))
        alert.addAction(UIAlertAction(title: L(.crashlyticsActionAlwaysSend), style: .default, handler: {(_ action: UIAlertAction) -> Void in
            DefaultsHelper.crashReportSetting = CrashlyticsAlwaysSend
            self.crashReportCompletion?(true)
            self.crashReportCompletion = nil
        }))
        alert.addAction(UIAlertAction(title: L(.crashlyticsActionDoNotSend), style: .cancel, handler: {(_ action: UIAlertAction) -> Void in
            self.crashReportCompletion?(false)
            self.crashReportCompletion = nil
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
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
            if determineFileExtension(mimeType: determineMimeType(url: newUrl)) == "asice" {
                do {
                    let newData: Data = try Data(contentsOf: newUrl)
                    let fileName: String = newUrl.deletingPathExtension().lastPathComponent
                    let fileURL: URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("\(fileName).asice")
                    do {
                        try newData.write(to: fileURL, options: .atomic)
                        newUrl = fileURL
                    } catch {
                        print("Error writing to file: \(error)")
                    }
                } catch {
                    print("Error getting directory: \(error)")
                }
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
        if var topViewController = UIApplication.shared.keyWindow?.rootViewController {
            while let currentViewController = topViewController.presentedViewController {
                topViewController = currentViewController
            }
            
            for childViewController in topViewController.childViewControllers {
                if childViewController is IdCardViewController {
                    MoppLibCardReaderManager.sharedInstance().startDiscoveringReaders()
                }
            }
        }
    }
    
    private func determineMimeType(url: URL) -> String {
        do {
            let urlData: Data = try Data(contentsOf: url)
            var bytes: UInt8 = 0
            urlData.copyBytes(to: &bytes, count: 1)
            
            /* Getting mimetype using UTTypeCopyPreferredTagWithClass does not give the correct result, converting file to NSData and using the content's first byte to get the correct value */
            if bytes == 80 {
                return "application/vnd.etsi.asic-e+zip"
            }
        } catch {
            print("Error getting url data \(error)")
        }
        
        return "application/octet-stream"
    }
    
    private func determineFileExtension(mimeType: String) -> String {
        if (mimeType == "application/vnd.etsi.asic-e+zip") {
            return "asice"
        }
        
        return ""
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

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

    var tabBarController: LandingTabBarController?
    var tempUrl: URL?
    var sourceApplication = ""
    var annotation: Any?
    var crashReportCompletion: ((_ submit: Bool) -> Void)? = nil
    var downloadCompletion: (() -> Void)? = nil
    var window: UIWindow?

    enum Nib : String {
        case containerElements = "ContainerElements"
        case signingElements = "SigningElements"
        case customElements = "CustomElements"
    }
    var nibs: [Nib: UINib] = [:]

    func didFinishLaunchingWithOptions(launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        loadNibs()
        Session.shared.setup()
        // Set navBar not translucent by default.
        Crashlytics.sharedInstance().delegate = self
        Fabric.with([Crashlytics.self])
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.white
        
        
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().tintColor = UIColor.moppText
        UINavigationBar.appearance().barTintColor = UIColor.moppBaseBackground
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.moppText]
        UINavigationBar.appearance().barStyle = .default
        
        // Selected TabBar item text color
        UITabBarItem.appearance().setTitleTextAttributes(
            [NSAttributedStringKey.foregroundColor:UIColor.white,
             NSAttributedStringKey.font:UIFont(name: "RobotoCondensed-Regular", size: 10)!],
            for: .selected)

        // Unselected TabBar item text color
        UITabBarItem.appearance().setTitleTextAttributes(
            [NSAttributedStringKey.foregroundColor:UIColor.moppUnselectedTabBarItem,
             NSAttributedStringKey.font:UIFont(name: "RobotoCondensed-Regular", size: 10)!],
            for: .normal)
        
        let initializationViewController = InitializationViewController()
        window?.rootViewController = initializationViewController
        window?.makeKeyAndVisible()
        return true
    }

    func crashlyticsDidDetectReport(forLastExecution report: CLSReport, completionHandler: @escaping (_ submit: Bool) -> Void) {
        if (DefaultsHelper.crashReportSetting == CrashlyticsAlwaysSend) {
            completionHandler(true)
        }
        else {
            crashReportCompletion = completionHandler
        }
    }

    func setupTabController() {
        tabBarController = UIStoryboard.landing.instantiateInitialViewController(of: LandingTabBarController.self)
        window?.rootViewController = tabBarController
        if let tempUrl = self.tempUrl {
            _ = openUrl(url: tempUrl, sourceApplication: sourceApplication, annotation: annotation)
            self.tempUrl = nil
            sourceApplication = String()
            annotation = nil
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

    func openUrl(url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if !url.absoluteString.isEmpty {
        
            // When app has just been launched, it may not be ready to deal with containers yet. We need to wait until libdigidocpp setup is complete.
            if tabBarController == nil {
                self.annotation = annotation
                self.sourceApplication = sourceApplication!
                tempUrl = url
                return true
            }
            
            let filePath = url.relativePath
            let fileName = url.lastPathComponent
            let fileExtension: String = URL(fileURLWithPath: filePath).pathExtension
            
            MSLog("Imported file: %@", filePath)
            
            let navController = tabBarController?.viewControllers[0] as? UINavigationController
                navController?.popViewController(animated: false)
            
            let signingViewController = navController?.viewControllers.first as? SigningViewController

            let openExistingContainer = fileExtension.isContainerExtension
         
            let failure: (() -> Void) = {
                
                let alert = UIAlertController(title: L(.fileImportImportFailedAlertTitle), message: L(.fileImportImportFailedAlertMessage, [fileName]), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))
    
                signingViewController?.present(alert, animated: true)
            }
            
            if openExistingContainer {
                
                // Move container from inbox folder to documents folder and cleanup.
                
                var newFilePath: String = MoppFileManager.shared.filePath(withFileName: fileName)
                    newFilePath = MoppFileManager.shared.copyFile(withPath: filePath, toPath: newFilePath)
                
                MoppFileManager.shared.removeFile(withPath: filePath)
            
                MoppLibContainerActions.sharedInstance().getContainerWithPath(newFilePath, success: {(_ container: MoppLibContainer?) -> Void in
                    guard let container = container else {
                        // Remove invalid container. Probably ddoc.
                        MoppFileManager.shared.removeFile(withName: fileName)
                        failure()
                        return
                    }
                    NotificationCenter.default.post(name: .openContainerNotificationName, object: nil, userInfo: [kKeyContainer: container])
                    
                }, failure: { _ in
                    failure()
                })
            } else {
            
                // Create new container
            
                let (filenameWithoutExt, _) = fileName.filenameComponents()
                let containerFilename = filenameWithoutExt + ".bdoc"
                var containerPath = MoppFileManager.shared.filePath(withFileName: containerFilename)
            
                containerPath = MoppFileManager.shared.duplicateFilename(atPath: containerPath)
            
                MoppLibContainerActions.sharedInstance().createContainer(withPath: containerPath, withDataFilePaths: [filePath], success: { container in
                    guard let container = container else {
                        failure()
                        return
                    }
                    let userInfo : [AnyHashable : Any] = [
                        kKeyContainer: container,
                        "isCreated": true
                        ]
            
                    NotificationCenter.default.post(name: .openContainerNotificationName, object: nil, userInfo: userInfo)
                    
                }, failure: { error in
                    MoppFileManager.shared.removeFile(withPath: filePath)
                })

            }
        }
        return true
    }

    func willResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func didEnterBackground() {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }


    func willEnterForeground() {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        NotificationCenter.default.post(name: .willEnterForegroundNotificationName, object: nil, userInfo: nil)
    }

    func didBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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

}

extension MoppApp {
    func loadNibs() {
        nibs[.containerElements] = UINib(nibName: Nib.containerElements.rawValue, bundle: Bundle.main)
        nibs[.signingElements] = UINib(nibName: Nib.signingElements.rawValue, bundle: Bundle.main)
        nibs[.customElements] = UINib(nibName: Nib.customElements.rawValue, bundle: Bundle.main)
    }
}

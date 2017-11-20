//
//  MoppApp.swift
//  MoppApp
//
//  Created by Sander Hunt on 19/11/2017.
//  Copyright © 2017 Riigi Infosüsteemide Amet. All rights reserved.
//

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

    func didFinishLaunchingWithOptions(launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
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
        print(Thread.isMainThread)
        print(UIStoryboard(name: "Landing", bundle: nil))
        tabBarController = UIStoryboard(name: "Landing", bundle: nil).instantiateInitialViewController() as? LandingTabBarController
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
        let alert = UIAlertController(title: L(.CrashlyticsTitle), message: L(.CrashlyticsMessage), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L(.CrashlyticsActionSend), style: .default, handler: { (_ action: UIAlertAction) in
            self.crashReportCompletion?(true)
            self.crashReportCompletion = nil
        }))
        alert.addAction(UIAlertAction(title: L(.CrashlyticsActionAlwaysSend), style: .default, handler: {(_ action: UIAlertAction) -> Void in
            DefaultsHelper.crashReportSetting = CrashlyticsAlwaysSend
            self.crashReportCompletion?(true)
            self.crashReportCompletion = nil
        }))
        alert.addAction(UIAlertAction(title: L(.CrashlyticsActionDoNotSend), style: .cancel, handler: {(_ action: UIAlertAction) -> Void in
            self.crashReportCompletion?(false)
            self.crashReportCompletion = nil
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
    }

    func openUrl(url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        /*if !url.absoluteString.isEmpty {
            // When app has just been launched, it may not be ready to deal with containers yet. We need to wait until libdigidocpp setup is complete.
            if tabBarController == nil {
                self.annotation = annotation
                self.sourceApplication = sourceApplication!
                tempUrl = url
                return true
            }
            let filePath = url.relativePath
            let fileName = filePath.lastPathComponent
            let fileExtension: String? = URL(fileURLWithPath: filePath).pathExtension
            MSLog("Imported file: %@", filePath)
            tabBarController?.selectedIndex = 0
            var navController = tabBarController?.viewControllers?[0] as? UINavigationController
            navController?.popViewController(animated: false)
            var containersListViewController = navController?.viewControllers[0] as? ContainersListViewController
         
            if (fileExtension == ContainerFormatDdoc) || (fileExtension == ContainerFormatAsice) || (fileExtension == ContainerFormatBdoc) {
                // Move container from inbox folder to documents folder and cleanup.
                var newFilePath: String = MoppFileManager.shared.filePath(withFileName: fileName)
                newFilePath = MoppFileManager.shared.copyFile(withPath: filePath, toPath: newFilePath)
                MoppFileManager.shared.removeFile(withPath: filePath)
                var failure: (() -> Void)? = {(_: Void) -> Void in
                    // Remove invalid container. Probably ddoc.
                    MoppFileManager.shared.removeFile(withName: fileName)
                    var alert = UIAlertController(title: L(.FileImportImportFailedAlertTitle), message: L(.FileImportImportFailedAlertMessage, fileName), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: L(.ActionOk), style: .default, handler: nil))
                    containersListViewController.present(alert, animated: true) { _ in }
                }
                MoppLibContainerActions.sharedInstance().getContainerWithPath(newFilePath, success: {(_ container: MoppLibContainer?) -> Void in
                    NotificationCenter.default.post(name: .containerChangedNotificationName, object: nil, userInfo: [kKeyContainerNew: container])
                    var moppLibContainer: MoppLibContainer? = container
                    if moppLibContainer != nil {
                        containersListViewController.selectedContainer = moppLibContainer
                    }
                    else {
                        failure?()
                    }
                }, failure: {(_ error: Error?) -> Void in
                    failure?()
                })
            } else {
                containersListViewController.dataFilePaths = [filePath]
            }
        }*/
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

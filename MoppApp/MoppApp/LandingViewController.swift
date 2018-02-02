//
//  LandingViewController.swift
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
protocol LandingViewControllerTabButtonsDelegate {
    func landingViewControllerTabButtonTapped(tabButtonId: LandingViewController.TabButtonId)
}

class LandingViewController : UIViewController
{
    var tabButtonsDelegate: LandingViewControllerTabButtonsDelegate? = nil
    var fileImportIntent: MoppApp.FileImportIntent!

    var importProgressViewController: FileImportProgressViewController = {
        let importProgressViewController = UIStoryboard.landing.instantiateViewController(with: FileImportProgressViewController.self)
            importProgressViewController.modalPresentationStyle = .overFullScreen
        return importProgressViewController
    }()

    @IBOutlet weak var containerViewBottomCSTR: NSLayoutConstraint!
    @IBOutlet weak var containerViewButtonBarCSTR: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet var buttonsCollection: [TabButton]!
    @IBOutlet weak var buttonBarView: UIView!

    @IBAction func selectTab(sender: UIButton)
     {
        let tabId = TabButtonId(rawValue: sender.superview!.accessibilityIdentifier!)!
        selectTabButton(tabId)
        
        if tabId == .signTab {
            selectedIndex = 0
        }
        else if tabId == .cryptoTab {
            selectedIndex = 1
        }
        else if tabId == .myeIDTab {
            selectedIndex = 2
        }
    }

    enum TabButtonId: String {
        case signTab
        case cryptoTab
        case myeIDTab
        case shareButton
        case signButton
        case encryptButton
    }

    var selectedIndex = 0 {
        didSet {
            for i in 0..<viewControllers.count {
                viewControllers[i].view.isHidden = selectedIndex != i
            }
        }
    }
    var viewControllers: [UIViewController] = []
    static private(set) var shared: LandingViewController!

    func configureConstraints(for targetView: UIView) {
        let margins = self.containerView.safeAreaLayoutGuide

        targetView.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        targetView.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        targetView.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        targetView.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
        targetView.translatesAutoresizingMaskIntoConstraints = false
        targetView.updateConstraints()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        LandingViewController.shared = self
        
        viewControllers.append(UIStoryboard.signing.instantiateInitialViewController()!)
        viewControllers.append(UIStoryboard.crypto.instantiateInitialViewController()!)
        viewControllers.append(UIStoryboard.myEID.instantiateInitialViewController()!)
        
        viewControllers.forEach { viewController in
            viewController.view.frame = view.bounds
            containerView.addSubview(viewController.view)
            viewController.view.frame = containerView.bounds
            configureConstraints(for: viewController.view)
            containerView.updateConstraints()
        }
        
        selectedIndex = 0
        
        buttonsCollection.forEach {
            if $0.kind == .button {
                $0.button.addTarget(self, action: #selector(tabButtonTapAction), for: .touchUpInside)
            }
        }
        
        presentButtons([.signTab, .cryptoTab, .myeIDTab])
        selectTabButton(.signTab)

        NotificationCenter.default.addObserver(self, selector: #selector(receiveErrorNotification), name: .errorNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveOpenContainerNotification), name: .openContainerNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveStartImportingFilesWithDocumentPickerNotification), name: .startImportingFilesWithDocumentPickerNotificationName, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        buttonsCollection.forEach {
            if $0.kind == .button {
                $0.button.removeTarget(self, action: #selector(tabButtonTapAction), for: .touchUpInside)
            }
        }
    }

    @objc func tabButtonTapAction(sender: UIButton) {
        let tabButton = buttonsCollection.first { $0.button == sender }!
        let buttonId = TabButtonId(rawValue: tabButton.accessibilityIdentifier!)!
        tabButtonsDelegate?.landingViewControllerTabButtonTapped(tabButtonId: buttonId)
    }

    func setupTab(for controller: UIViewController, title: String, image imageName: String, selectedImage selectedImageName: String) {
        controller.title = title
        let selectedImage = UIImage(named: imageName)
        let image: UIImage? = selectedImage?.applyingAlpha(UIColor.moppUnselectedTabBarItemAlpha).withRenderingMode(.alwaysOriginal)
        controller.tabBarItem.image = image
        controller.tabBarItem.selectedImage = selectedImage
    }

    @objc func receiveOpenContainerNotification(_ notification: Notification) {
        guard let container = notification.userInfo?[kKeyContainer] as? MoppLibContainer else {
            return
        }
        
        let isCreated = (notification.userInfo?["isCreated"] as? Bool) ?? false
        
        navigationController?.dismiss(animated: true, completion: nil)
        
        // Select signing tab
        selectedIndex = 0
        if let navigationController = viewControllers.first as? UINavigationController {
            let containerViewController = ContainerViewController.instantiate()
                containerViewController.containerPath = container.filePath
                containerViewController.isCreated = isCreated
            navigationController.pushViewController(containerViewController, animated: false)
        }
    }

    @objc func receiveErrorNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let error = userInfo[kErrorKey] as? NSError
        var errorMessage = error?.userInfo[NSLocalizedDescriptionKey] as? String ??
            userInfo[kErrorMessage] as? String
        
        if errorMessage == "USER_CANCEL" {
            errorMessage = MoppLib_LocalizedString("digidoc-service-status-request-user-cancel")
        }
        else if errorMessage == "EXPIRED_TRANSACTION" {
            errorMessage = MoppLib_LocalizedString("digidoc-service-status-request-expired-transaction")
        }
        
        let alert = UIAlertController(
            title: L(.errorAlertTitleGeneral),
            message: errorMessage,
            preferredStyle: .alert)
        
        presentedViewController?.dismiss(animated: true, completion: nil)
        alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    @objc func receiveStartImportingFilesWithDocumentPickerNotification(_ notification: Notification) {
        let allowedDocumentTypes = ["public.content", "public.data", "public.image", "public.movie", "public.audio", "public.item"]
    
        fileImportIntent = notification.userInfo![kKeyFileImportIntent] as! MoppApp.FileImportIntent
    
        let documentPicker = UIDocumentPickerViewController(documentTypes: allowedDocumentTypes, in: .import)
            documentPicker.modalPresentationStyle = .overCurrentContext
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = true
        
        present(documentPicker, animated: false, completion: nil)
    }

    func importFiles(with urls: [URL]) {
        let navController = viewControllers[0] as! UINavigationController
        let topSigningViewController = navController.viewControllers.last!
        
        topSigningViewController.present(importProgressViewController, animated: false)
        
        MoppFileManager.shared.importFiles(with: urls) { [weak self] error, dataFilePaths in
            guard let strongSelf = self else { return }
        
            if strongSelf.fileImportIntent == .addToContainer {
                self?.addDataFilesToContainer(dataFilePaths: dataFilePaths)
            }
            else if strongSelf.fileImportIntent == .openOrCreate {
                navController.setViewControllers([navController.viewControllers.first!], animated: false)
             
                let ext = urls.first!.pathExtension
                if (ext.isContainerExtension || ext == ContainerFormatPDF) && urls.count == 1 {
                    self?.openExistingContainer(with: urls.first!)
                } else {
                    self?.createNewContainer(with: urls.first!, dataFilePaths: dataFilePaths)
                }
            }
        }
    }

    func addDataFilesToContainer(dataFilePaths: [String]) {
        let navController = viewControllers[0] as! UINavigationController
        let topSigningViewController = navController.viewControllers.last!
        let containerViewController = topSigningViewController as? ContainerViewController
        let containerPath = containerViewController!.containerPath
        MoppLibContainerActions.sharedInstance().addDataFilesToContainer(
            withPath: containerPath,
            withDataFilePaths: dataFilePaths,
            success: { [weak self] container in
                self?.importProgressViewController.dismiss(animated: false, completion: nil)
                containerViewController?.reloadContainer()
            },
            failure: { [weak self] error in
                self?.importProgressViewController.dismiss(animated: false, completion: nil)
            }
        )
    }
    
    func openExistingContainer(with url: URL) {
        // Move container from inbox folder to documents folder and cleanup.
        let filePath = url.relativePath
        let fileName = url.lastPathComponent

        let navController = viewControllers[0] as! UINavigationController
        let topSigningViewController = navController.viewControllers.last!
        var containerViewController = topSigningViewController as? ContainerViewController

        var newFilePath: String = MoppFileManager.shared.filePath(withFileName: fileName)
            newFilePath = MoppFileManager.shared.copyFile(withPath: filePath, toPath: newFilePath)

        MoppFileManager.shared.removeFile(withPath: filePath)

        let failure: (() -> Void) = { [weak self] in
            
            self?.importProgressViewController.dismiss(animated: false, completion: nil)
            
            let alert = UIAlertController(title: L(.fileImportImportFailedAlertTitle), message: L(.fileImportImportFailedAlertMessage, [fileName]), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))

            navController.viewControllers.first!.present(alert, animated: true)
        }

        MoppLibContainerActions.sharedInstance().getContainerWithPath(newFilePath,
            success: { [weak self] (_ container: MoppLibContainer?) -> Void in
                if container == nil {
                    // Remove invalid container. Probably ddoc.
                    MoppFileManager.shared.removeFile(withName: fileName)
                    failure()
                    return
                }
            
                self?.importProgressViewController.dismiss(animated: false, completion: nil)
            
                // If file to open is PDF and there is no signatures then create new container
                if url.pathExtension.lowercased() == ContainerFormatPDF && container!.signatures.isEmpty {
                    self?.createNewContainer(with: url, dataFilePaths: [newFilePath])
                    return
                }
            
                containerViewController = ContainerViewController.instantiate()
                containerViewController?.containerPath = newFilePath
                
                navController.pushViewController(containerViewController!, animated: true)
            },
            failure: { _ in
                failure()
            }
        )
    }
    
    func createNewContainer(with url: URL, dataFilePaths: [String]) {
        let filePath = url.relativePath
        let fileName = url.lastPathComponent
        
        let (filename, _) = fileName.filenameComponents()
        let containerFilename = filename + ".bdoc"
        var containerPath = MoppFileManager.shared.filePath(withFileName: containerFilename)

        containerPath = MoppFileManager.shared.duplicateFilename(atPath: containerPath)

        let navController = viewControllers[0] as! UINavigationController
        let topSigningViewController = navController.viewControllers.last!
        var containerViewController = topSigningViewController as? ContainerViewController

        MoppLibContainerActions.sharedInstance().createContainer(
            withPath: containerPath,
            withDataFilePaths: dataFilePaths,
            success: { [weak self] container in
                if container == nil {
                    self?.importProgressViewController.dismiss(animated: false, completion: nil)
                    
                    let alert = UIAlertController(title: L(.fileImportImportFailedAlertTitle), message: L(.fileImportImportFailedAlertMessage, [fileName]), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: L(.actionOk), style: .default, handler: nil))

                    navController.viewControllers.first!.present(alert, animated: true)
                    return
                }
            
                self?.importProgressViewController.dismiss(animated: false, completion: nil)
            
                containerViewController = ContainerViewController.instantiate()
                containerViewController?.containerPath = containerPath
                containerViewController?.isCreated = true
                
                navController.pushViewController(containerViewController!, animated: true)
            
            }, failure: { [weak self] error in
                self?.importProgressViewController.dismiss(animated: false, completion: nil)
                MoppFileManager.shared.removeFile(withPath: filePath)
            }
        )
    }
}

extension LandingViewController : UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        importFiles(with: urls)
    }
}

extension LandingViewController {
    func presentButtons(_ buttons: [TabButtonId]) {
        buttonBarView.isHidden = buttons.isEmpty
        if buttons.isEmpty {
            containerViewBottomCSTR.priority = .defaultHigh
            containerViewButtonBarCSTR.priority = .defaultLow
        } else {
            containerViewBottomCSTR.priority = .defaultLow
            containerViewButtonBarCSTR.priority = .defaultHigh
        }
        view.layoutIfNeeded()
        for b in buttons {
            self.buttonsCollection.first(where: { $0.accessibilityIdentifier == b.rawValue })?.isHidden = false
        }
        let buttonsToHide = self.buttonsCollection.filter {
            !buttons.contains(TabButtonId(rawValue: $0.accessibilityIdentifier!)!)
        }
        buttonsToHide.forEach {
            $0.isHidden = true
        }
    }
    
    func selectTabButton(_ button: TabButtonId) {
        for b in buttonsCollection {
            if b.kind == .tab {
                let id = TabButtonId(rawValue: b.accessibilityIdentifier!)!
                b.setSelected(id == button)
            }
        }
    }
}

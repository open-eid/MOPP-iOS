//
//  MyeIDViewController.swift
//  MoppApp
//
/*
 * Copyright 2021 Riigi Infosüsteemi Amet
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
class MyeIDViewController : MoppViewController {
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var containerView: UIView!
    var changingCodesVCPresented: Bool = false
    
    var infoManager: MyeIDInfoManager!
 
    override func viewDidLoad() {
        super.viewDidLoad()
        infoManager = MyeIDInfoManager()
        infoManager.delegate = self
    
        let statusVC = createStatusViewController()
        _ = showViewController(statusVC)
        
        MoppLibCardReaderManager.sharedInstance().delegate = self
        
        menuButton.accessibilityLabel = L(.menuButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        LandingViewController.shared.presentButtons([.signTab, .cryptoTab, .myeIDTab])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !changingCodesVCPresented {
            let statusVC = childViewControllers.first as? MyeIDStatusViewController
                statusVC?.state = .readerNotFound
        
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                MoppLibCardReaderManager.sharedInstance().startDiscoveringReaders()
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !changingCodesVCPresented {
            MoppLibCardReaderManager.sharedInstance().stopDiscoveringReaders()
        }
    }
    
    func createStatusViewController() -> MyeIDStatusViewController {
        return UIStoryboard.myEID.instantiateViewController(of: MyeIDStatusViewController.self)
    }
    
    func createInfoViewController() -> MyeIDInfoViewController {
        let infoViewController = UIStoryboard.myEID.instantiateViewController(of: MyeIDInfoViewController.self)
            infoViewController.infoManager = infoManager
        return infoViewController
    }
    
    func showViewController(_ viewController: MoppViewController) -> UIViewController {
        let oldViewController = childViewControllers.first
        let newViewController = viewController

        if type(of: oldViewController) == type(of: newViewController) {
            return newViewController
        }
        
        oldViewController?.willMove(toParentViewController: nil)
        addChildViewController(newViewController)
        
        oldViewController?.removeFromParentViewController()
        newViewController.didMove(toParentViewController: self)
    
        newViewController.view.translatesAutoresizingMaskIntoConstraints = false
    
        oldViewController?.view.removeFromSuperview()
        containerView.addSubview(newViewController.view)
    
        let margins = containerView.safeAreaLayoutGuide
        let leading = newViewController.view.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
        let trailing = newViewController.view.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
        let top = newViewController.view.topAnchor.constraint(equalTo: margins.topAnchor)
        let bottom = newViewController.view.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
    
        leading.isActive    = true
        trailing.isActive   = true
        top.isActive        = true
        bottom.isActive     = true

        newViewController.view.updateConstraintsIfNeeded()
        return newViewController
    }
    
    func popChangeCodesViewControllerIfPushed() {
        if let _ = navigationController?.viewControllers.last as? MyeIDChangeCodesViewController {
            navigationController?.popViewController(animated: false)
        }
    }
}

extension MyeIDViewController: MoppLibCardReaderManagerDelegate {
    func moppLibCardReaderStatusDidChange(_ readerStatus: MoppLibCardReaderStatus) {
        switch readerStatus {
        case .ReaderNotConnected:
            popChangeCodesViewControllerIfPushed()
            var statusVC = childViewControllers.first as? MyeIDStatusViewController
            if statusVC == nil {
                statusVC = showViewController(createStatusViewController()) as? MyeIDStatusViewController
            }
            statusVC?.state = .readerNotFound
        case .ReaderConnected:
            popChangeCodesViewControllerIfPushed()
            var statusVC = childViewControllers.first as? MyeIDStatusViewController
            if statusVC == nil {
                statusVC = showViewController(createStatusViewController()) as? MyeIDStatusViewController
            }
            statusVC?.state = .idCardNotFound
        case .CardConnected:
            popChangeCodesViewControllerIfPushed()
            var statusVC = childViewControllers.first as? MyeIDStatusViewController
            if statusVC == nil {
                statusVC = showViewController(createStatusViewController()) as? MyeIDStatusViewController
            }
            statusVC?.state = .requestingData
            
            // Give some time for status textfield to update before executing data requests
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.infoManager.requestInformation(with: strongSelf)
            })
        }
    }
}

extension MyeIDViewController: MyeIDInfoManagerDelegate {
    func didCompleteInformationRequest(success:Bool) {
        if success {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                let infoViewController = strongSelf.createInfoViewController()
                _ = strongSelf.showViewController(infoViewController)
            }
        } else {
            childViewControllers.first?.errorAlert(message: L(.genericErrorMessage))
        }
    }
    
    func didTapChangePinPukCode(actionType: MyeIDChangeCodesModel.ActionType) {
        let changeCodesViewController = UIStoryboard.myEID.instantiateViewController(of: MyeIDChangeCodesViewController.self)
            changeCodesViewController.model = MyeIDInfoManager.createChangeCodesModel(actionType: actionType)
            changeCodesViewController.infoManager = infoManager
        
        changingCodesVCPresented = true
        navigationController?.pushViewController(changeCodesViewController, animated: true)
    }
}

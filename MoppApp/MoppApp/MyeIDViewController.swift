//
//  MyeIDViewController.swift
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
class MyeIDViewController : MoppViewController {
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var containerView: UIView!
    var changingCodesVCPresented: Bool = false
    var didRestartReader = false
    
    var infoManager: MyeIDInfoManager!
    var cardCommands: CardCommands?

    override func viewDidLoad() {
        super.viewDidLoad()
        infoManager = MyeIDInfoManager()
        infoManager.delegate = self
    
        let statusVC = createStatusViewController()
        _ = showViewController(statusVC)
        
        MoppLibCardReaderManager.shared.delegate = self

        menuButton.accessibilityLabel = L(.menuButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        LandingViewController.shared.presentButtons([.signTab, .cryptoTab, .myeIDTab])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !changingCodesVCPresented {
            let statusVC = children.first as? MyeIDStatusViewController
                statusVC?.state = .readerNotFound

            MoppLibCardReaderManager.shared.startDiscoveringReaders()
        } else {
            changingCodesVCPresented = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !changingCodesVCPresented {
            MoppLibCardReaderManager.shared.stopDiscoveringReaders()
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
        let oldViewController = children.first
        let newViewController = viewController

        if type(of: oldViewController) == type(of: newViewController) {
            return newViewController
        }
        
        oldViewController?.willMove(toParent: nil)
        addChild(newViewController)
        
        oldViewController?.removeFromParent()
        newViewController.didMove(toParent: self)
    
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
    
    func popViewControllerIfPushed() {
        if let _ = navigationController?.viewControllers.last as? MyeIDStatusViewController {
            navigationController?.popViewController(animated: false)
        }
    }
}

extension MyeIDViewController: MoppLibCardReaderManagerDelegate {
    func moppLibCardReaderStatusDidChange(_ readerStatus: MoppLibCardReaderStatus) {
        popChangeCodesViewControllerIfPushed()
        var statusVC = children.first as? MyeIDStatusViewController
        if statusVC == nil {
            statusVC = showViewController(createStatusViewController()) as? MyeIDStatusViewController
        }
        cardCommands = nil
        switch readerStatus {
        case .Initial: statusVC?.state = .initial
        case .ReaderNotConnected: statusVC?.state = .readerNotFound
        case .ReaderRestarted: statusVC?.state = .readerRestarted
        case .ReaderConnected: statusVC?.state = .idCardNotFound
        case .CardConnected(let cardCommands): statusVC?.state = .requestingData
            self.cardCommands = cardCommands
            infoManager.requestInformation(cardCommands)
        case .ReaderProcessFailed: statusVC?.state = .readerProcessFailed
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
            if didRestartReader {
                printLog("ID-CARD: My eID. Reader already restarted")
                moppLibCardReaderStatusDidChange(.ReaderProcessFailed)
                return
            }
            printLog("ID-CARD: My eID. Restarting reader")
            didRestartReader = true
            MoppLibCardReaderManager.shared.stopDiscoveringReaders(with: .ReaderRestarted)
            MoppLibCardReaderManager.shared.startDiscoveringReaders()
        }
    }
    
    func didTapChangePinPukCode(actionType: MyeIDChangeCodesModel.ActionType) {
        let changeCodesViewController = UIStoryboard.myEID.instantiateViewController(of: MyeIDChangeCodesViewController.self)
            changeCodesViewController.model = MyeIDInfoManager.createChangeCodesModel(actionType: actionType, cardCommands: cardCommands)
            changeCodesViewController.infoManager = infoManager
        
        changingCodesVCPresented = true
        navigationController?.pushViewController(changeCodesViewController, animated: true)
    }
}

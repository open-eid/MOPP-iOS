//
//  MyeIDViewController.swift
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
class MyeIDViewController : MoppViewController {
    @IBOutlet weak var containerView: UIView!
 
    override func viewDidLoad() {
        super.viewDidLoad()
    
        MyeIDInfoManager.shared.delegate = self
    
        _ = showViewController(createStatusViewController())
        MoppLibCardReaderManager.sharedInstance().delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MoppLibCardReaderManager.sharedInstance().startDetecting()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MoppLibCardReaderManager.sharedInstance().stopDetecting()
    }
    
    func createStatusViewController() -> MyeIDStatusViewController {
        return UIStoryboard.myEID.instantiateViewController(of: MyeIDStatusViewController.self)
    }
    
    func createInfoViewController() -> MyeIDInfoViewController {
        return UIStoryboard.myEID.instantiateViewController(of: MyeIDInfoViewController.self)
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
}

extension MyeIDViewController: MoppLibCardReaderManagerDelegate {
    func moppLibCardReaderStatusDidChange(_ readerStatus: MoppLibCardReaderStatus) {
        switch readerStatus {
        case .ReaderNotConnected:
            var statusVC = childViewControllers.first as? MyeIDStatusViewController
            if statusVC == nil {
                statusVC = showViewController(createStatusViewController()) as? MyeIDStatusViewController
            }
            statusVC?.state = .readerNotFound
        case .ReaderConnected:
            var statusVC = childViewControllers.first as? MyeIDStatusViewController
            if statusVC == nil {
                statusVC = showViewController(createStatusViewController()) as? MyeIDStatusViewController
            }
            statusVC?.state = .idCardNotFound
        case .CardConnected:
            var statusVC = childViewControllers.first as? MyeIDStatusViewController
            if statusVC == nil {
                statusVC = showViewController(createStatusViewController()) as? MyeIDStatusViewController
            }
            statusVC?.state = .requestingData
            
            // Give some time for status textfield to update before executing data requests
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
                guard let strongSelf = self else { return }
                MyeIDInfoManager.shared.requestInformation(with: strongSelf)
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
    
    func didTapChangePinPukCode(kind: MyeIDInfoManager.PinPukCell.Kind) {
    }
}

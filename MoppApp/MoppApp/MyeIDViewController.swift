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
    
    let statusViewController: MyeIDStatusViewController = {
        UIStoryboard.myEID.instantiateViewController(with: MyeIDStatusViewController.self)
    }()
    
    let infoViewController: MyeIDInfoViewController = {
        UIStoryboard.myEID.instantiateViewController(with: MyeIDInfoViewController.self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        showViewController(statusViewController)
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
    
    func showViewController(_ viewController: MoppViewController) {
        let oldViewController = childViewControllers.first
        let newViewController = viewController

        if oldViewController == newViewController {
            return
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
    }
}

extension MyeIDViewController: MoppLibCardReaderManagerDelegate {
    func moppLibCardReaderStatusDidChange(_ readerStatus: MoppLibCardReaderStatus) {
        switch readerStatus {
        case .ReaderNotConnected:
            statusViewController.state = .readerNotFound
            showViewController(statusViewController)
        case .ReaderConnected:
            statusViewController.state = .idCardNotFound
            showViewController(statusViewController)
        case .CardConnected:
            MoppLibCardActions.minimalCardPersonalData(with: self, success: { [weak self] moppLibPersonalData in
                DispatchQueue.main.async { [weak self] in
                    guard let sself = self else { return }
                    sself.infoViewController.loadItems(personalData: moppLibPersonalData)
                    sself.showViewController(sself.infoViewController)
                }
            }, failure: { [weak self]_ in
                
            })
        }
    }
}

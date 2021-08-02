//
//  ScreenDisguise.swift
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
import UIKit


public class ScreenDisguise: NSObject {
    public static let shared = ScreenDisguise()
    private var viewController: ScreenDisguiseViewController? = nil
    
    var uiVisualEffectView = UIVisualEffectView()
    var blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
    private func getTopViewController() -> UIViewController? {
        guard let keyWindow = UIApplication.shared.keyWindow, let topViewController = keyWindow.rootViewController?.getTopViewController() else {
            return nil
        }
        
        return topViewController
    }
    
    public func show() {
        guard let keyWindow = UIApplication.shared.keyWindow, let topViewController = keyWindow.rootViewController?.getTopViewController() else {
            return
        }
        
        if !uiVisualEffectView.isDescendant(of: keyWindow) {
            UIView.animate(withDuration: 0.05) {
                self.uiVisualEffectView.effect = UIBlurEffect(style: .light)
                self.uiVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
                self.uiVisualEffectView.frame = keyWindow.bounds
            }
            
            keyWindow.addSubview(uiVisualEffectView)
            
            if (topViewController is MobileIDChallengeViewController || topViewController is SmartIDChallengeViewController) {
                keyWindow.rootViewController?.view.addSubview(uiVisualEffectView)
                uiVisualEffectView.contentView.bringSubviewToFront(topViewController.view)
            }
        }
    }
    
    public func hide() {
        guard let keyWindow = UIApplication.shared.keyWindow else { return }
        UIView.animate(withDuration: 0.25, animations: {
            self.uiVisualEffectView.alpha = 0.0
            keyWindow.alpha = 1.0
        }, completion: {(value: Bool) in
            self.uiVisualEffectView.removeFromSuperview()
        })
    }
    
    public func handleScreenRecordingPrevention() {
        let isScreenBeingCaptured: Bool = UIScreen.main.isCaptured
        
        guard let topViewController: UIViewController = getTopViewController() else { return }
        
        if isScreenBeingCaptured {
            show()
            if let launchScreenView = Bundle.main.loadNibNamed("LaunchScreen", owner: self, options: nil)?.last as? UIView {
                launchScreenView.tag = launchScreenTag
                topViewController.view.addSubview(launchScreenView)
                topViewController.view.bringSubviewToFront(launchScreenView)
                hide()
                
                // Pin to edges
                let layoutGuide = topViewController.view.safeAreaLayoutGuide
                launchScreenView.translatesAutoresizingMaskIntoConstraints = false
                launchScreenView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
                launchScreenView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
                launchScreenView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor).isActive = true
                launchScreenView.topAnchor.constraint(equalTo: topViewController.view.topAnchor).isActive = true
            }
            
            
        } else {
            if let launchScreenView = getTopViewController()?.view.viewWithTag(launchScreenTag) {
                launchScreenView.removeFromSuperview()
                hide()
            } else {
                print("Unable to find view with tag \(launchScreenTag)")
            }
        }
    }
}

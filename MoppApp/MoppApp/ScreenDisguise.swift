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


public class ScreenDisguise {
    public static let shared = ScreenDisguise()
    private var viewController: ScreenDisguiseViewController? = nil
    
    var uiVisualEffectView = UIVisualEffectView()
    var blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
    private init() {}
    
    public func show() {
        if #available(iOS 12, *) {
            guard let keyWindow = UIApplication.shared.keyWindow, let topViewController = keyWindow.rootViewController?.getTopViewController() else {
                return
            }
            
            if !uiVisualEffectView.isDescendant(of: keyWindow) {
                UIView.animate(withDuration: 0.05) {
                    self.uiVisualEffectView.effect = UIBlurEffect(style: .light)
                    self.uiVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
                    self.uiVisualEffectView.frame = keyWindow.bounds
                }
                
                topViewController.view.addSubview(uiVisualEffectView)
                
                if (topViewController is MobileIDChallengeViewController || topViewController is SmartIDChallengeViewController) {
                    keyWindow.rootViewController?.view.addSubview(uiVisualEffectView)
                    uiVisualEffectView.contentView.bringSubviewToFront(topViewController.view)
                }
            }
        }
    }
    
    public func hide() {
        if #available(iOS 12, *) {
            guard let keyWindow = UIApplication.shared.keyWindow else { return }
            UIView.animate(withDuration: 0.25, animations: {
                self.uiVisualEffectView.alpha = 0.0
                keyWindow.alpha = 1.0
            }, completion: {(value: Bool) in
                self.uiVisualEffectView.removeFromSuperview()
            })
        }
    }
}

//
//  ScreenDisguise.swift
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
import UIKit


public class ScreenDisguise {
    public static let shared = ScreenDisguise()
    private var viewController: ScreenDisguiseViewController? = nil
    
    var uiVisualEffectView = UIVisualEffectView()
    var blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
    private init() {}
    
    public func show() {
        if #available(iOS 12, *) {
            if !uiVisualEffectView.isDescendant(of: UIApplication.shared.keyWindow!) {
                UIView.animate(withDuration: 0.05) {
                    self.uiVisualEffectView.effect = UIBlurEffect(style: .light)
                    self.uiVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
                    self.uiVisualEffectView.frame = (UIApplication.shared.keyWindow?.bounds)!
                }
                
                UIApplication.shared.keyWindow?.addSubview(uiVisualEffectView)
            }
        }
    }
    
    public func hide() {
        if #available(iOS 12, *) {
            UIView.animate(withDuration: 0.25, animations: {
                self.uiVisualEffectView.alpha = 0.0
                UIApplication.shared.keyWindow!.alpha = 1.0
            }, completion: {(value: Bool) in
                self.uiVisualEffectView.removeFromSuperview()
            })
        }
    }
}

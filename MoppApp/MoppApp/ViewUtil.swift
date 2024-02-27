//
//  ViewUtil.swift
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

import UIKit

class ViewUtil {
    
    static func focusOnView(_ notification: NSNotification, mainView: UIView, scrollView: UIScrollView) {
        if let view = notification.userInfo?["view"] as? UIView {
            mainView.endEditing(true)
            for subview in mainView.subviews {
                if view === subview {
                    scrollView.setContentOffset(CGPoint(x: 0, y: subview.frame.origin.y / 2), animated: true)
                    return
                } else if let superView = view.superview, superView.isKind(of: UIStackView.self) {
                    scrollView.setContentOffset(CGPoint(x: 0, y: superView.frame.origin.y / 2), animated: true)
                    return
                } else {
                    focusOnView(notification, mainView: subview, scrollView: scrollView)
                }
            }
        }
    }
}

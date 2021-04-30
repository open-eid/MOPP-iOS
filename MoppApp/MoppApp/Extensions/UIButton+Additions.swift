//
//  UIButton+Additions.swift
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


extension UIButton {
    func setLocalizedTitle(_ key: LocKey, _ arguments: [CVarArg] = []) {
        setTitle(L(key, arguments), for: .normal)
        setTitle(L(key, arguments), for: .selected)
        setTitle(L(key, arguments), for: .disabled)
    }
    
    var localizedTitle: LocKey? {
        set {
            if let key = newValue {
                setTitle(L(key), for: .normal)
                setTitle(L(key), for: .selected)
                setTitle(L(key), for: .disabled)
            } else {
                setTitle(nil, for: .normal)
                setTitle(nil, for: .selected)
                setTitle(nil, for: .disabled)
            }
        }
        get { return nil /* Getter is unsed */ }
    }
    
    func setTitle(_ title: String?) {
        setTitle(title, for: .normal)
        setTitle(title, for: .disabled)
        setTitle(title, for: .highlighted)
    }
}

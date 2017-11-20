//
//  UIButton+Additions.swift
//  MoppApp
//
//  Created by Sander Hunt on 20/11/2017.
//  Copyright © 2017 Riigi Infosüsteemide Amet. All rights reserved.
//

import Foundation


extension UIButton {
    func setLocalizedTitle(_ key: LocKey, _ arguments: Any...) {
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
}

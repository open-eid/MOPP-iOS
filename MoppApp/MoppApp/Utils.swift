//
//  Utils.swift
//  MoppApp
//
//  Created by Sander Hunt on 14/11/2017.
//  Copyright © 2017 Riigi Infosüsteemide Amet. All rights reserved.
//

import Foundation

func MSLog(_ format: String, _ arguments: Any...) {
    print(format, arguments)
}

func L(_ key: LocKey, _ arguments: Any...) -> String {
    let format = NSLocalizedString(key.rawValue, comment: String())
    return String(format: format, arguments)
}

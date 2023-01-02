//
//  UIStoryBoard+Additions.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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


extension UIStoryboard {
    static var landing: UIStoryboard {
        return UIStoryboard(name: "Landing", bundle: Bundle.main)
    }

    static var container: UIStoryboard {
        return UIStoryboard(name: "Container", bundle: Bundle.main)
    }

    static var menu: UIStoryboard {
        return UIStoryboard(name: "Menu", bundle: Bundle.main)
    }

    static var signing: UIStoryboard {
        return UIStoryboard(name: "Signing", bundle: Bundle.main)
    }

    static var tokenFlow: UIStoryboard {
        return UIStoryboard(name: "TokenFlow", bundle: Bundle.main)
    }
    
    static var myEID: UIStoryboard {
        return UIStoryboard(name: "MyeID", bundle: Bundle.main)
    }
    
    static var crypto: UIStoryboard {
        return UIStoryboard(name: "Crypto", bundle: Bundle.main)
    }
    
    static var recentContainers: UIStoryboard {
        return UIStoryboard(name: "RecentContainers", bundle: Bundle.main)
    }
    
    static var accessibility: UIStoryboard {
        return UIStoryboard(name: "Accessibility", bundle: Bundle.main)
    }
    
    static var settings: UIStoryboard {
        return UIStoryboard(name: "Settings", bundle: Bundle.main)
    }
    
    static var jailbreak: UIStoryboard {
        return UIStoryboard(name: "Jailbreak", bundle: Bundle.main)
    }
}

extension UIStoryboard {
    func instantiateViewController<T: UIViewController>(of type: T.Type) -> T {
        return instantiateViewController(withIdentifier: String(describing: T.self)) as! T
    }
    
    func instantiateInitialViewController<T: UIViewController>(of type: T.Type) -> T {
        return instantiateInitialViewController() as! T
    }
}

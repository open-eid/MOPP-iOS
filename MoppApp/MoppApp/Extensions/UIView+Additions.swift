//
//  UIView+Additions.swift
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


extension UIView {
    func createGradientLayer(topColor: UIColor, bottomColor: UIColor) {
    
        // Remove previously added gradient layer
        if let sublayers = layer.sublayers {
            if let sl = sublayers.first(where:{ $0.name == "__backgroundGradient" }) {
                sl.removeFromSuperlayer()
            }
        }
    
        let result = CAGradientLayer()
            result.name = "__backgroundGradient"
            result.colors = [topColor.cgColor, bottomColor.cgColor]
            result.frame = bounds
            layer.insertSublayer(result, at: 0)
    }
}

//
//  NSObject+UIImage_Additions.swift
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

extension UIImage {
    func applyingAlpha(_ alpha: CGFloat) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        guard let ctx = UIGraphicsGetCurrentContext(), let cgImage = cgImage else {
            return UIImage()
        }
        
        let area = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        ctx.scaleBy(x: 1, y: -1)
        ctx.translateBy(x: 0, y: -area.size.height)
        ctx.setBlendMode(.multiply)
        ctx.setAlpha(alpha)
        ctx.draw(cgImage, in: area)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage ?? UIImage()
    }
}

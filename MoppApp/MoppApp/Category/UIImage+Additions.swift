//
//  NSObject+UIImage_Additions.m
//  MoppApp
//
//  Created by Sander Hunt on 13/11/2017.
//  Copyright © 2017 Riigi Infosüsteemide Amet. All rights reserved.
//

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

//
//  RadioButton.swift
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

import UIKit
class RadioButton: UIView {

    let nibName = "RadioButton"
    
    var isSelectedState: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var accessType: SivaAccess = .defaultAccess

    @IBOutlet weak var outerLayer: UIView!
    @IBOutlet weak var middleLayer: UIView!
    @IBOutlet weak var innerLayer: UIView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        guard let view = loadView() else { return }
        outerLayer.layer.cornerRadius = outerLayer.frame.height / 2
        outerLayer.layer.borderWidth = 2
        outerLayer.layer.borderColor = UIColor.moppBase.cgColor
        outerLayer.layer.backgroundColor = UIColor.clear.cgColor
        
        middleLayer.layer.cornerRadius = middleLayer.frame.height / 2
        middleLayer.layer.borderColor = UIColor.clear.cgColor
        middleLayer.layer.backgroundColor = UIColor.clear.cgColor
        
        innerLayer.layer.borderWidth = 2
        innerLayer.layer.cornerRadius = innerLayer.frame.height / 2
        innerLayer.layer.borderColor = UIColor.moppBase.cgColor
        innerLayer.layer.backgroundColor = UIColor.moppBase.cgColor

        view.frame = self.bounds
        self.addSubview(view)
    }
    
    func setSelectedState(state: Bool) {
        isSelectedState = state
        innerLayer.isHidden = !isSelectedState
    }

    func loadView() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
}

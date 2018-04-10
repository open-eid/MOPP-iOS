//
//  MyeIDPinPukCell.swift
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
protocol MyeIDPinPukCellDelegate: class {
    func didTapChangeCodeButton()
}

class MyeIDPinPukCell: UITableViewCell {
    weak var delegate: MyeIDPinPukCellDelegate? = nil
    
    var kind: MyeIDInfoManager.PinPukCell.Kind!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var certInfoLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var bottomLine: UIView!
    
    @IBAction func changeCodeAction() {
        MyeIDInfoManager.shared.delegate?.didTapChangePinPukCode(kind: kind)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func populate(pinPukCellInfo: MyeIDInfoManager.PinPukCell.Info) {
        kind = pinPukCellInfo.kind
        titleLabel.text = pinPukCellInfo.title
        linkLabel.attributedText = NSAttributedString(string: pinPukCellInfo.linkText, attributes: [.underlineStyle : NSUnderlineStyle.styleSingle.rawValue])
        button.setTitle(pinPukCellInfo.buttonText)
        
        if let certInfoText = pinPukCellInfo.certInfoText {
            certInfoLabel.text = certInfoText
        } else {
            var certExpiryDate: Date? = nil
            if kind == .pin1 {
                certExpiryDate = MyeIDInfoManager.shared.authCertData?.expiryDate
            }
            else if kind == .pin2 {
                certExpiryDate = MyeIDInfoManager.shared.signCertData?.expiryDate
            }
        
            let font = UIFont(name: MoppFontName.regular.rawValue, size: 16)!
        
            let certInfoString = NSMutableAttributedString()
            certInfoString.append(NSAttributedString(
                string: L(.myEidCertInfoPrefix),
                attributes: [.font: font]
                ))
            var valid: Bool = false
            certInfoString.append(MyeIDInfoManager.shared.expiryDateAttributedString(date: certExpiryDate, font: font, capitalized: false, valid: &valid) ?? NSAttributedString())
            
            if valid {
                if let expiryDate = certExpiryDate {
                    certInfoString.append(NSAttributedString(string: L(.myEidCertInfoValidSuffix)))
                    let dateString = MyeIDInfoManager.shared.expiryDateFormatter.string(from: expiryDate)
                    certInfoString.append(NSAttributedString(string: dateString))
                }
            } else {
                if let expiryDate = certExpiryDate {
                    certInfoString.append(NSAttributedString(string: L(.myEidCertInfoExpiredSuffix)))
                    let dateString = MyeIDInfoManager.shared.expiryDateFormatter.string(from: expiryDate)
                    certInfoString.append(NSAttributedString(string: dateString))
                }
            }
            
            certInfoLabel.text = nil
            certInfoLabel.font = nil
            certInfoLabel.attributedText = certInfoString
            certInfoLabel.setNeedsDisplay()
        }
    }
}

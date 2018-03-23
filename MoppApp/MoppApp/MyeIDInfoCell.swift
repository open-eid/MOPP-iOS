//
//  MyeIDInfoCell.swift
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
class MyeIDInfoCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func populate(titleText: String, contentText: String) {
        titleLabel.text = titleText
        contentLabel.text = contentText
    }
    
    func populate(titleText: String, with expirationDate: Date?) {
        guard let expirationDate = expirationDate else { return }
        //let expirationDate = Date()
        let documentExpired = expirationDate < Date()
        let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
        let dateStr = dateFormatter.string(from: expirationDate)
        titleLabel.text = titleText
        
        let attrText = NSMutableAttributedString(string: dateStr + " | ")
        
        if documentExpired {
            let expiredText = NSAttributedString(string: "Aegunud", attributes:
                [NSAttributedStringKey.foregroundColor : UIColor.moppError,
                 NSAttributedStringKey.font : UIFont(name: MoppFontName.allCapsBold.rawValue, size: 17)!])
            attrText.append(expiredText)
        } else {
            let validText = NSAttributedString(string: "Kehtiv", attributes:
                [NSAttributedStringKey.foregroundColor : UIColor.moppSuccess,
                 NSAttributedStringKey.font : UIFont(name: MoppFontName.allCapsBold.rawValue, size: 17)!])
            attrText.append(validText)
        }
        
        contentLabel.attributedText = attrText
    }
}

//
//  DiagnosticsViewController.swift
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
class DiagnosticsViewController: MoppViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var opSysVersionLabel: UILabel!
    @IBOutlet weak var librariesTitleLabel: UILabel!
    @IBOutlet weak var librariesLabel: UILabel!

    @IBAction func dismissAction() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        titleLabel.text = L(.diagnosticsTitle)
        appVersionLabel.attributedText = attributedTextForBoldRegularText(key: L(.diagnosticsAppVersion) + ": ", value: MoppApp.versionString)
        opSysVersionLabel.attributedText = attributedTextForBoldRegularText(key: L(.diagnosticsIosVersion) + ": ", value: "iOS " +  MoppApp.iosVersion)
        librariesTitleLabel.attributedText = attributedTextForBoldRegularText(key: L(.diagnosticsLibrariesLabel), value: String())
        let libdigidocppVersion = MoppLibManager.sharedInstance().libdigidocppVersion() ?? String()
        librariesLabel.attributedText = attributedTextForBoldRegularText(key: String(), value: "libdigidocpp \(libdigidocppVersion)")
    }
    
    func attributedTextForBoldRegularText(key:String, value:String) -> NSAttributedString {
        let regularFont = UIFont(name: MoppFontName.regular.rawValue, size: 16)!
        let boldFont = UIFont(name: MoppFontName.bold.rawValue, size: 16)!
        let textColor = UIColor.moppText
        
        let result = NSMutableAttributedString(string: key, attributes: [NSAttributedStringKey.font : boldFont, NSAttributedStringKey.foregroundColor : textColor])
            result.append(NSAttributedString(string: value, attributes: [NSAttributedStringKey.font : regularFont, NSAttributedStringKey.foregroundColor : textColor]))
        return result
    }
}

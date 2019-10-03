//
//  MenuLanguageCell.swift
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
class MenuLanguageCell : UITableViewCell {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewContainerView: UIView!
    weak var delegate: MenuLanguageCellDelegate? = nil
    
    enum AvailableLanguages: String {
        case estonian = "Eesti keel"
        case english = "English"
        case russian = "Русский язык"
    }
    
    var currentLanguage: String {
        return DefaultsHelper.moppLanguageID
    }
    
    func languageButtonView(_ id: String) -> MenuLanguageButtonView {
        return stackView.arrangedSubviews.first { $0.accessibilityIdentifier == id  } as! MenuLanguageButtonView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
                
        stackViewContainerView.layer.cornerRadius = 5
        stackViewContainerView.layer.borderColor = UIColor.moppMenuSeparator.cgColor
        stackViewContainerView.layer.borderWidth = 1
    
        for view in (stackView.arrangedSubviews as! [MenuLanguageButtonView]) {
            switch view.label.text {
            case AvailableLanguages.estonian.rawValue:
                view.button.accessibilityLabel = L(.languageEstonian)
                break
            case AvailableLanguages.english.rawValue:
                view.button.accessibilityLabel = L(.languageEnglish)
                break
            case AvailableLanguages.russian.rawValue:
                view.button.accessibilityLabel = L(.languageRussian)
                break
            default:
                break
            }
            view.button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        let buttonView = sender.superview as! MenuLanguageButtonView
        let langId = buttonView.accessibilityIdentifier!
        selectLanguage(langId)
        
        delegate?.didSelectLanguage(languageId: langId)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        selectLanguage(currentLanguage)
    }
    
    func selectLanguage(_ langId: String) {
        for view in (stackView.arrangedSubviews as! [MenuLanguageButtonView]) {
            view.isSelected = view.accessibilityIdentifier! == langId
        }
    }
}

protocol MenuLanguageCellDelegate : class {
    func didSelectLanguage(languageId: String)
}

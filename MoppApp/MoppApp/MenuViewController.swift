//
//  MenuViewController.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
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
class MenuViewController : MoppModalViewController {
    @IBOutlet weak var tableView        : UITableView!
    @IBOutlet weak var helpButton       : UIButton!
    @IBOutlet weak var introButton      : UIButton!
    @IBOutlet weak var documentsButton  : UIButton!
    @IBOutlet weak var settingsButton   : UIButton!
    @IBOutlet weak var aboutButton      : UIButton!

    enum Section {
        case header
        case items
    }

    let sections: [Section] = [.header, .items]

    enum MenuItemID {
        case help
        case accessibility
        case settings
        case about
        case diagnostics
        case language
        case separator
    }

    let menuItems: [(title: String, imageName: String, id: MenuItemID)] = [
        (L(.menuHelp), "icon_help white", .help),
        (L(.menuAccessibility), "icon_accessibility white", .accessibility),
        (L(.menuSettings), "icon_settings white", .settings),
        (L(.menuAbout), "icon_info white", .about),
        (L(.menuDiagnostics), "icon_graph white", .diagnostics),
        (String(), String(), .separator),
        (String(), String(), .language)
        ]

    @IBAction func dismissAction() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableView.automaticDimension
        
        lightContentStatusBarStyle = true
    
        let blurLayer = CALayer()
        if let filter = CIFilter(name: "CIGaussianBlur") {
            blurLayer.backgroundFilters = [filter]
            view.layer.addSublayer(blurLayer)
        }
    }
}

extension MenuViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section_: Int) -> Int {
        let section = sections[section_]
        switch section {
        case .header:
            return 1
        case .items:
            return menuItems.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Set custom height for header section
        if indexPath.section == 0 {
            return 100
        }
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        switch section {
        case .header:
            let cell = tableView.dequeueReusableCell(withType: MenuHeaderCell.self, for: indexPath)!
                cell.delegate = self
            return cell
        case .items:
            let title = menuItems[indexPath.row].title
            let iconName = menuItems[indexPath.row].imageName
            let id = menuItems[indexPath.row].id
            if id == .language {
                let cell = tableView.dequeueReusableCell(withType: MenuLanguageCell.self, for: indexPath)!
                    cell.delegate = self
                return cell
            } else if id == .separator {
                let cell = tableView.dequeueReusableCell(withType: MenuSeparatorCell.self, for: indexPath)!
                cell.accessibilityElementsHidden = true
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withType: MenuCell.self, for: indexPath)!
                    cell.populate(iconName: iconName, title: title)
                if id == .help {
                    cell.accessibilityTraits = UIAccessibilityTraits.link
                } else {
                    cell.accessibilityTraits = UIAccessibilityTraits.button
                }
                return cell
            }
        }

    }
}

extension MenuViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        if section == .items {
            switch menuItems[indexPath.row].id {
            case .help:
                let appLanguageID = DefaultsHelper.moppLanguageID
                var helpUrl: URL!
                if appLanguageID == "et" {
                    helpUrl = URL(string: "https://www.id.ee/id-abikeskus/")
                }
                else if appLanguageID == "ru" {
                    helpUrl = URL(string: "https://www.id.ee/ru/id-pomoshh/")
                }
                else {
                    helpUrl = URL(string: "https://www.id.ee/en/id-help/")
                }
                if helpUrl != nil {
                    MoppApp.shared.open(helpUrl, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                }
            case .accessibility:
                DispatchQueue.main.async(execute: {
                    self.dismiss(animated: true) {
                        let accessibilityViewController = UIStoryboard.accessibility.instantiateInitialViewController(of: AccessibilityViewController.self)
                        accessibilityViewController.modalPresentationStyle = .overFullScreen
                        MoppApp.instance.rootViewController?.present(accessibilityViewController, animated: true, completion: nil)
                    }
                })
                break
            case .settings:
                DispatchQueue.main.async(execute: {
                    self.dismiss(animated: true) {
                        let settingsViewController = UIStoryboard.settings.instantiateInitialViewController(of: SettingsViewController.self)
                            settingsViewController.modalPresentationStyle = .overFullScreen
                        MoppApp.instance.rootViewController?.present(settingsViewController, animated: true, completion: nil)
                    }
                })
            case .about:
                DispatchQueue.main.async(execute: {
                    self.dismiss(animated: true) {
                        MoppApp.instance.rootViewController?.present(MoppApp.instance.aboutViewController, animated: true, completion: nil)
                    }
                })
            case .diagnostics:
                DispatchQueue.main.async(execute: {
                    self.dismiss(animated: true) {
                        let diagnosticsViewController = UIStoryboard.settings.instantiateViewController(of: DiagnosticsViewController.self)
                            diagnosticsViewController.modalPresentationStyle = .overFullScreen
                        MoppApp.instance.rootViewController?.present(diagnosticsViewController, animated: true, completion: nil)
                    }
                })
            case .language:
                break
            case .separator:
                break
            }
        }
    }
    
}

extension MenuViewController : MenuHeaderDelegate {
    func menuHeaderDismiss() {
        dismiss(animated: true, completion: nil)
    }
}

extension MenuViewController : MenuLanguageCellDelegate {
    func didSelectLanguage(languageId: String) {
        
        DefaultsHelper.moppLanguageID = languageId
        
        dismiss(animated: true) {
            MoppApp.instance.resetRootViewController()
        }
        
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

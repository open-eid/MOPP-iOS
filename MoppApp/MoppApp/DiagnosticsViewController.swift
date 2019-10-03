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
    @IBOutlet weak var centralConfigurationLabel: UILabel!
    @IBOutlet weak var updateDateLabel: UILabel!
    @IBOutlet weak var lastCheckLabel: UILabel!
    @IBOutlet weak var refreshConfigurationLabel: UIButton!
    
    @IBOutlet weak var configURL: UILabel!
    @IBOutlet weak var tslURL: UILabel!
    @IBOutlet weak var sivaURL: UILabel!
    @IBOutlet weak var tsaURL: UILabel!
    @IBOutlet weak var midSignURL: UILabel!
    @IBOutlet weak var ldapPersonURL: UILabel!
    @IBOutlet weak var ldapCorpURL: UILabel!
    @IBOutlet weak var metaDate: UILabel!
    @IBOutlet weak var metaSerial: UILabel!
    @IBOutlet weak var metaUrl: UILabel!
    @IBOutlet weak var metaVer: UILabel!
    @IBOutlet weak var updateDate: UILabel!
    @IBOutlet weak var lastCheckDate: UILabel!
    
    @IBAction func refreshConfiguration(_ sender: Any) {
        SettingsConfiguration().loadCentralConfiguration()
        self.viewDidLoad()
    }
    
    
    
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
        centralConfigurationLabel.text = L(.centralConfigurationLabel)
        refreshConfigurationLabel.setTitle(L(.refreshConfigurationLabel))
        
        configurationToUI()
        
        listenForConfigUpdates()
    }
    
    func attributedTextForBoldRegularText(key:String, value:String) -> NSAttributedString {
        let regularFont = UIFont(name: MoppFontName.regular.rawValue, size: 16)!
        let boldFont = UIFont(name: MoppFontName.bold.rawValue, size: 16)!
        let textColor = UIColor.moppText
        
        let result = NSMutableAttributedString(string: key, attributes: [NSAttributedStringKey.font : boldFont, NSAttributedStringKey.foregroundColor : textColor])
        result.append(NSAttributedString(string: value, attributes: [NSAttributedStringKey.font : regularFont, NSAttributedStringKey.foregroundColor : textColor]))
        return result
    }
    
    func listenForConfigUpdates() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleConfigurationLoaded(notification:)), name: .configurationLoaded, object: nil)
    }
    
    @objc func handleConfigurationLoaded(notification: Notification) {
        self.viewDidLoad()
    }
    
    private func configurationToUI() {
        let decodedConf = getMoppConfiguration()
        
        configURL.text = formatString(text: "CONFIG_URL:", additionalText: decodedConf.METAINF.URL)
        tslURL.text = formatString(text: "TSL_URL:", additionalText: decodedConf.TSLURL)
        sivaURL.text = formatString(text: "SIVA_URL:", additionalText: decodedConf.SIVAURL)
        tsaURL.text = formatString(text: "TSA_URL:", additionalText: decodedConf.TSAURL)
        midSignURL.text = formatString(text: "MID-SIGN-URL:", additionalText: decodedConf.MIDSIGNURL)
        ldapPersonURL.text = formatString(text: "LDAP_PERSON_URL:", additionalText: decodedConf.LDAPPERSONURL)
        ldapCorpURL.text = formatString(text: "LDAP_CORP_URL:", additionalText: decodedConf.LDAPCORPURL)
        
        metaDate.text = formatString(text: "DATE:", additionalText: decodedConf.METAINF.DATE)
        
        metaSerial.text = formatString(text: "SERIAL:", additionalText: String(decodedConf.METAINF.SERIAL))
        
        metaUrl.text = formatString(text: "URL:", additionalText: decodedConf.METAINF.URL)
        
        metaVer.text = formatString(text: "VER:", additionalText: String(decodedConf.METAINF.VER))
        
        
        if let cachedUpdateDate = SettingsConfiguration().getConfigurationFromCache(forKey: "updateDate") as? Date {
            updateDate.text = formatString(text: L(.updateDateLabel), additionalText: MoppDateFormatter().dateToString(date: cachedUpdateDate))
        } else {
            do {
                updateDate.text = formatString(text: L(.updateDateLabel), additionalText: try getDecodedDefaultMoppConfiguration().UPDATEDATE)
            } catch {
                MSLog("Unable to decode data: ", error.localizedDescription)
            }
        }
        
        if let cachedLastUpdateCheckDate = SettingsConfiguration().getConfigurationFromCache(forKey: "lastUpdateCheckDate") as? Date {
            lastCheckDate.text = formatString(text: L(.lastUpdateCheckDateLabel), additionalText: MoppDateFormatter().dateToString(date: cachedLastUpdateCheckDate))
        } else {
            lastCheckDate.text = formatString(text: L(.lastUpdateCheckDateLabel), additionalText: " ")
        }
    }
    
    private func getMoppConfiguration() -> MOPPConfiguration {
        return Configuration.getConfiguration()
    }
    
    private func getDecodedDefaultMoppConfiguration() throws -> DefaultMoppConfiguration {
        do {
            let defaultConfigData = try String(contentsOfFile: Bundle.main.path(forResource: "defaultConfiguration", ofType: "json")!)
            return try MoppConfigurationDecoder().decodeDefaultMoppConfiguration(configData: defaultConfigData)
        } catch {
            MSLog("Unable to decode data: ", error.localizedDescription)
            throw error
        }
    }
}

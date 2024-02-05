//
//  DiagnosticsViewController.swift
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
class DiagnosticsViewController: MoppViewController, UIDocumentPickerDelegate {

    private var isSavingOneTimeLog = false

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var opSysVersionLabel: UILabel!
    @IBOutlet weak var librariesTitleLabel: UILabel!
    @IBOutlet weak var librariesLabel: UILabel!
    @IBOutlet weak var urlsLabel: UILabel!
    @IBOutlet weak var tslCacheLabel: UILabel!
    @IBOutlet weak var centralConfigurationLabel: UILabel!
    @IBOutlet weak var updateDateLabel: UILabel!
    @IBOutlet weak var lastCheckLabel: UILabel!
    @IBOutlet weak var refreshConfigurationLabel: UIButton!
    @IBOutlet weak var saveDiagnosticsLabel: UIButton!
    @IBOutlet weak var enableOneTimeLoggingLabel: UILabel!
    @IBOutlet weak var oneTimeLoggingSwitch: UISwitch!
    @IBAction func fileLoggingSwitchChanged(_ sender: Any) {
        handleFileLoggingSwitchChanged()
    }
    @IBOutlet weak var saveLogButtonLabel: UIButton!
    @IBAction func saveLogButton(_ sender: Any) {
        isSavingOneTimeLog = true
        handleSaveOneTimeLog()
    }


    @IBOutlet weak var configURL: UILabel!
    @IBOutlet weak var tslURL: UILabel!
    @IBOutlet weak var sivaURL: UILabel!
    @IBOutlet weak var tsaURL: UILabel!
    @IBOutlet weak var ldapPersonURL: UILabel!
    @IBOutlet weak var ldapCorpURL: UILabel!
    @IBOutlet weak var mobileIdURL: UILabel!
    @IBOutlet weak var mobileIdSKURL: UILabel!
    @IBOutlet weak var smartIdURL: UILabel!
    @IBOutlet weak var smartIdSKURL: UILabel!
    @IBOutlet weak var smartIdV2URL: UILabel!
    @IBOutlet weak var smartIdV2SKUrl: UILabel!
    @IBOutlet weak var rpUUIDInfo: UILabel!
    @IBOutlet weak var tsls: UIStackView!
    @IBOutlet weak var metaDate: UILabel!
    @IBOutlet weak var metaSerial: UILabel!
    @IBOutlet weak var metaUrl: UILabel!
    @IBOutlet weak var metaVer: UILabel!
    @IBOutlet weak var updateDate: UILabel!
    @IBOutlet weak var lastCheckDate: UILabel!

    @IBAction func refreshConfiguration(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {
            printLog("Refreshing central configuration")
            SettingsConfiguration().loadCentralConfiguration() { error in
                DispatchQueue.main.async {
                    if case DiagnosticError.noInternetConnection = error {
                        self.infoAlert(message: L(.noConnectionMessage))
                    }
                }
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.onCentralConfigurationResponse(responseNotification:)), name: SettingsConfiguration.isCentralConfigurationLoaded, object: nil)
        }
    }

    @IBAction func saveDiagnostics(_ sender: Any) {
        printLog("Saving diagnostics")
        printLog("Formatting diagnostics data")
        let diagnosticsText = formatDiagnosticsText()
        let fileName = "ria_digidoc_\(MoppApp.versionString)_diagnostics.txt"
        printLog("Saving diagnostics to file '\(fileName)'")
        saveDiagnosticsToFile(fileName: fileName, diagnosticsText: diagnosticsText)
    }

    @IBOutlet weak var dismissButton: UIButton!

    @IBAction func dismissAction() {
        printLog("Closing diagnostics view")
        dismiss(animated: true, completion: nil)
    }

    @objc func onCentralConfigurationResponse(responseNotification: Notification) {
        printLog("Central configuration response received")
        DispatchQueue.main.async {
            self.configurationToUI()
        }
        if responseNotification.userInfo?["isLoaded"] as! Bool == true {
            DispatchQueue.main.async { [weak self] in
                self?.viewDidLoad()
                if UIAccessibility.isVoiceOverRunning {
                    UIAccessibility.post(notification: .screenChanged, argument: L(.refreshConfigurationUpdated))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        printLog("Showing configuration refresh message")
                        self?.displayMessageDialog(message: L(.refreshConfigurationRestartMessage))
                    }
                } else {
                    printLog("Showing configuration refresh message")
                    self?.displayMessageDialog(message: L(.refreshConfigurationRestartMessage))
                }
            }
        } else {
            printLog("Configuration is already up to date")
            UIAccessibility.post(notification: .screenChanged, argument: L(.refreshConfigurationAlreadyUpToDate))
        }
    }

    override func loadView() {
        super.loadView()

        printLog("Initialized Diagnostics view")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        printLog("Setting up diagnostics data")

        titleLabel.text = L(.diagnosticsTitle)
        appVersionLabel.text = "\(L(.diagnosticsAppVersion)): \(MoppApp.versionString)"
        opSysVersionLabel.text = "\(L(.diagnosticsIosVersion)): iOS \(MoppApp.iosVersion)"
        librariesTitleLabel.text = L(.diagnosticsLibrariesLabel)
        let libdigidocppVersion = MoppLibManager.sharedInstance().libdigidocppVersion() ?? String()
        librariesLabel.text = "libdigidocpp \(libdigidocppVersion)"
        tslCacheLabel.text = L(.diagnosticsTslCacheLabel)
        centralConfigurationLabel.text = L(.centralConfigurationLabel)
        refreshConfigurationLabel.setTitle(L(.refreshConfigurationLabel))
        saveDiagnosticsLabel.setTitle(L(.saveDiagnosticsLabel))
        
        tsls.isAccessibilityElement = false

        dismissButton.setTitle(L(.closeButton))

        enableOneTimeLoggingLabel.text = L(.diagnosticsActivateOneTimeLogging)
        enableOneTimeLoggingLabel.isAccessibilityElement = false
        
        oneTimeLoggingSwitch.accessibilityLabel = enableOneTimeLoggingLabel.text
        oneTimeLoggingSwitch.accessibilityUserInputLabels = [L(.voiceControlEnableLogGeneration)]

        if FileLogUtil.isLoggingEnabled() {
            saveLogButtonLabel.isHidden = false
            saveLogButtonLabel.localizedTitle = .diagnosticsSaveLog
            oneTimeLoggingSwitch.accessibilityUserInputLabels = [L(.voiceControlDisableLogGeneration)]
        } else {
            oneTimeLoggingSwitch.setOn(false, animated: true)
            saveLogButtonLabel.isHidden = true
            oneTimeLoggingSwitch.accessibilityUserInputLabels = [L(.voiceControlEnableLogGeneration)]
        }

        NotificationCenter.default.addObserver(self, selector: #selector(handleOneTimeLogging), name: UIApplication.didEnterBackgroundNotification, object: nil)

        configurationToUI()

        listenForConfigUpdates()
    }

    // If user clicks on "Additional information", set the switch back to "Off" state
    @objc func handleOneTimeLogging() {
        if !FileLogUtil.isLoggingEnabled() {
            oneTimeLoggingSwitch.setOn(false, animated: true)
            oneTimeLoggingSwitch.accessibilityUserInputLabels = [L(.voiceControlEnableLogGeneration)]
        }
    }

    func attributedTextForBoldRegularText(key:String, value:String) -> NSAttributedString {
        let regularFont = UIFont(name: MoppFontName.regular.rawValue, size: 16)!
        let boldFont = UIFont(name: MoppFontName.bold.rawValue, size: 16)!
        let textColor = UIColor.moppText

        let result = NSMutableAttributedString(string: key, attributes: [NSAttributedString.Key.font : boldFont, NSAttributedString.Key.foregroundColor : textColor])
        result.append(NSAttributedString(string: value, attributes: [NSAttributedString.Key.font : regularFont, NSAttributedString.Key.foregroundColor : textColor]))
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
        tslURL.text = formatString(text: "TSL_URL:", additionalText: "\(getMoppConfiguration().TSLURL) \(formatLOTLVersion(version: getLOTLVersion()))")
        sivaURL.text = formatString(text: "SIVA_URL:", additionalText: decodedConf.SIVAURL)
        tsaURL.text = formatString(text: "TSA_URL:", additionalText: DefaultsHelper.timestampUrl ?? decodedConf.TSAURL)
        ldapPersonURL.text = formatString(text: "LDAP_PERSON_URL:", additionalText: decodedConf.LDAPPERSONURL)
        ldapCorpURL.text = formatString(text: "LDAP_CORP_URL:", additionalText: decodedConf.LDAPCORPURL)
        mobileIdURL.text = formatString(text: "MID-PROXY-URL: ", additionalText: decodedConf.MIDPROXYURL)
        mobileIdSKURL.text = formatString(text: "MID-SK-URL: ", additionalText: decodedConf.MIDSKURL)
        smartIdV2URL.text = formatString(text: "SIDV2-PROXY-URL: ", additionalText: decodedConf.SIDV2PROXYURL)
        smartIdV2SKUrl.text = formatString(text: "SIDV2-SK-URL: ", additionalText: decodedConf.SIDV2SKURL)
        rpUUIDInfo.text = formatString(text: "RPUUID: ", additionalText: getRPUUIDInfo())
        metaDate.text = formatString(text: "DATE:", additionalText: decodedConf.METAINF.DATE)
        metaSerial.text = formatString(text: "SERIAL:", additionalText: String(decodedConf.METAINF.SERIAL))
        metaUrl.text = formatString(text: "URL:", additionalText: decodedConf.METAINF.URL)
        metaVer.text = formatString(text: "VER:", additionalText: String(decodedConf.METAINF.VER))

        // Remove TSL cache labels
        for tslLabel in tsls.subviews {
            tslLabel.removeFromSuperview()
        }
        // Set TSL cache files with versions
        let filesInBundle: [URL] = TSLUpdater.getCountryFileLocations(inPath: TSLUpdater.getLibraryDirectoryPath())
        for fileInBundle in filesInBundle {
            let tslLabel = ScaledLabel()
            let tslVersion = TSLUpdater.getTSLVersion(fromFile: fileInBundle)
            tslLabel.text = formatString(text: fileInBundle.lastPathComponent, additionalText: "(\(tslVersion))")
            tsls.addArrangedSubview(tslLabel)
        }
        
        printLog("Getting cached update date")
        if let cachedUpdateDate = SettingsConfiguration().getConfigurationFromCache(forKey: "updateDate") as? Date {
            updateDate.text = formatString(text: L(.updateDateLabel), additionalText: MoppDateFormatter().dateToString(date: cachedUpdateDate))
            printLog("Cached update date: \(MoppDateFormatter().dateToString(date: cachedUpdateDate))")
        } else {
            do {
                printLog("Cached update date not available. Getting default configuration update date")
                let defaultUpdateDate = try getDecodedDefaultMoppConfiguration().UPDATEDATE
                updateDate.text = formatString(text: L(.updateDateLabel), additionalText: defaultUpdateDate)
                printLog("Default update date: \(defaultUpdateDate)")
            } catch {
                printLog("Unable to decode data: \(error.localizedDescription)")
            }
        }

        printLog("Getting cached last update date")
        if let cachedLastUpdateCheckDate = SettingsConfiguration().getConfigurationFromCache(forKey: "lastUpdateCheckDate") as? Date {
            lastCheckDate.text = formatString(text: L(.lastUpdateCheckDateLabel), additionalText: MoppDateFormatter().dateToString(date: cachedLastUpdateCheckDate))
            printLog("Cached last update date: \(MoppDateFormatter().dateToString(date: cachedLastUpdateCheckDate))")
        } else {
            printLog("Last update check date not available")
            lastCheckDate.text = formatString(text: L(.lastUpdateCheckDateLabel), additionalText: " ")
        }
    }

    private func getMoppConfiguration() -> MOPPConfiguration {
        return Configuration.getConfiguration()
    }

    private func getDecodedDefaultMoppConfiguration() throws -> DefaultMoppConfiguration {
        printLog("Decoding default configuration")
        do {
            let defaultConfigData = try String(contentsOfFile: Bundle.main.path(forResource: "defaultConfiguration", ofType: "json")!)
            return try MoppConfigurationDecoder().decodeDefaultMoppConfiguration(configData: defaultConfigData)
        } catch {
            printLog("Unable to decode data: \(error.localizedDescription)")
            throw error
        }
    }

    private func getLOTLVersion() -> String {
        printLog("Getting LOTL version")
        let lotlFileUrl: URL? = TSLUpdater.getLOTLFileURL()
        guard lotlFileUrl != nil, let lotlFile = lotlFileUrl else {
            printLog("Unable to get LOTL file")
            return ""
        }
        let fileLocation: URL? = URL(fileURLWithPath: lotlFile.path)
        guard let fileURL: URL = fileLocation else { printLog("Failed to get eu-lotl file location"); return "" }
        do {
            printLog("Checking if LOTL file (\(lotlFile.lastPathComponent) is reachable at \(fileURL)")
            _ = try fileURL.checkResourceIsReachable()
        } catch let error {
            printLog("Failed to check if eu-lotl.xml file is reachable. Error: \(error.localizedDescription)")
            return ""
        }
        var version: String = ""
        TSLVersionChecker().getTSLVersion(filePath: fileURL) { (tslVersion) in
            printLog("Received TSL version: \(tslVersion)")
            if !tslVersion.isEmpty {
                version = tslVersion
            } else {
                printLog("TSL version is empty")
            }
        }

        return version
    }

    private func formatLOTLVersion(version: String) -> String {
        return version.isEmpty ? "" : "(\(version))"
    }

    private func getTSLVersion(for tslCountry: String) -> String {
        printLog("Getting TSL version")
        let libraryPath: String = MoppFileManager.shared.libraryDirectoryPath()
        let filesInLibrary: [URL] = TSLUpdater.getCountryFileLocations(inPath: libraryPath)

        for libraryFile in filesInLibrary {
            if !libraryFile.hasDirectoryPath {
                let fileName: String = libraryFile.deletingPathExtension().lastPathComponent
                if fileName == tslCountry {
                    let tslVersion: Int = TSLUpdater.getTSLVersion(fromFile: libraryFile)
                    return tslVersion == 0 ? "-" : String(tslVersion)
                }
            }
        }

        return "-"
    }

    private func getRPUUIDInfo() -> String {
        printLog("Getting RP UUID info")
        return DefaultsHelper.rpUuid.isEmpty || DefaultsHelper.rpUuid == kRelyingPartyUUID ?
            L(.diagnosticsRpUuidDefault) : L(.diagnosticsRpUuidCustom)
    }

    private func getAllTextLabels(view: UIView) -> [UILabel] {
        var uiLabels = [UILabel]()
        for subview in view.subviews {
            if subview is UILabel && !(subview is UIButton) {
                uiLabels.append(subview as! UILabel)
            } else {
                uiLabels.append(contentsOf: getAllTextLabels(view: subview))
            }
        }

        return uiLabels
    }

    private func formatDiagnosticsText() -> String {
        var diagnosticsText = ""
        for label in getAllTextLabels(view: view) {
            if let text = label.text, !isTitleOrButtonLabel(text: text) {
                if isCategoryLabel(text: text) {
                    diagnosticsText.append("\n\n\(text)\n")
                } else {
                    diagnosticsText.append("\(text)\n")
                }
            }
        }

        return diagnosticsText
    }

    private func isTitleOrButtonLabel(text: String) -> Bool {
        return isTitleLabel(text: text) || isButtonLabel(text: text)
    }

    private func isTitleLabel(text: String) -> Bool {
        return text == L(.diagnosticsTitle)
    }

    private func isButtonLabel(text: String) -> Bool {
        return text == L(.refreshConfigurationLabel) || text == L(.saveDiagnosticsLabel) || text == L(.diagnosticsActivateOneTimeLogging) || text == L(.diagnosticsSaveLog) || text == L(.closeButton)
    }

    private func isCategoryLabel(text: String) -> Bool {
        return text == L(.diagnosticsLibrariesLabel) || text == "URLs:" || text == L(.diagnosticsTslCacheLabel) || text == L(.centralConfigurationLabel)
    }

    private func saveDiagnosticsToFile(fileName: String, diagnosticsText: String) {
        let fileLocation: URL? = MoppFileManager.cacheDirectory.appendingPathComponent(fileName)

        if let fileUrl = fileLocation {
            printLog("Diagnostics file location: \(fileUrl)")
            do {
                if MoppFileManager.shared.fileExists(fileUrl.path) {
                    printLog("Diagnostics file already exists. Removing old diagnostics file")
                    MoppFileManager.shared.removeFile(withPath: fileUrl.path)
                }

                printLog("Writing diagnostics text to file")
                try diagnosticsText.write(to: fileUrl, atomically: true, encoding: .utf8)

                if MoppFileManager.shared.fileExists(fileUrl.path) {
                    printLog("Diagnostics file exists at \(fileUrl)")
                    saveToDisk(fileUrl: fileUrl)
                    return
                }
            } catch {
                printLog("Unable to write diagnostics to file. Error: \(error.localizedDescription)")
                self.infoAlert(message: L(.fileImportFailedFileSave))
                return
            }
        }
    }

    func saveToDisk(fileUrl: URL) {
        let pickerController = UIDocumentPickerViewController(url: fileUrl, in: .exportToService)
        pickerController.delegate = self
        self.present(pickerController, animated: true) {
            printLog("Showing file saving location picker")
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if !urls.isEmpty {
            let savedFileLocation: URL? = urls.first
            printLog("File (\(savedFileLocation?.lastPathComponent ?? "Not available") export done. Location: \(savedFileLocation?.path ?? "Not available")")
            self.infoAlert(message: L(.fileImportFileSaved))
            if isSavingOneTimeLog {
                disableLogging()
            }
        } else {
            printLog("Failed to save file")
            return self.infoAlert(message: L(.fileImportFailedFileSave))
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        printLog("File saving cancelled")
    }

    private func handleFileLoggingSwitchChanged() {
        if oneTimeLoggingSwitch.isOn {
            oneTimeLoggingSwitch.accessibilityUserInputLabels = [L(.voiceControlDisableLogGeneration)]
            let messageAlert = AlertUtil.messageAlertWithLink(message: L(.diagnosticsRestartToActivateLogging), additionalInfoButtonTitle: L(.diagnosticsOneTimeLoggingReadMore)) { _ in
                FileLogUtil.enableLogging()
            }
            present(messageAlert, animated: true)
        } else {
            disableLogging()
        }
    }

    private func handleSaveOneTimeLog() {
        do {
            let logFile = try FileLogUtil.combineLogFiles()
            saveToDisk(fileUrl: logFile)
        } catch {
            printLog("Unable to write logs to file. Error: \(error.localizedDescription)")
            self.infoAlert(message: L(.fileImportFailedFileSave))
            return
        }
    }

    private func disableLogging() {
        FileLogUtil.disableLoggingAndRemoveFiles()
        oneTimeLoggingSwitch.setOn(false, animated: true)
        oneTimeLoggingSwitch.accessibilityUserInputLabels = [L(.voiceControlEnableLogGeneration)]
        saveLogButtonLabel.isHidden = true
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        printLog("Deinit Diagnostics view")
    }
}

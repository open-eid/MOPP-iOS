//
//  AboutViewController.swift
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
import WebKit

class AboutViewController: MoppViewController, WKNavigationDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var dismissButton: UIButton!
    
    @IBAction func dismissAction() {
        dismiss(animated: true, completion: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        webView.navigationDelegate = self
        webView.configuration.preferences.javaScriptEnabled = false

        titleLabel.text = L(.aboutTitle)
        
        guard let titleUILabel = titleLabel, let dismissUIButton = dismissButton, let webUIView = webView else {
            NSLog("Unable to get titleLabel, dismissButton or webView")
            return
        }
        
        self.view.accessibilityElements = [titleUILabel, dismissUIButton, webUIView]
        
        var localizedAboutHtmlPath:String!
        let appLanguageID = DefaultsHelper.moppLanguageID
        if appLanguageID == "et" {
            localizedAboutHtmlPath = Bundle.main.path(forResource: "about_et", ofType: "html")!
        }
        else if appLanguageID == "ru" {
            localizedAboutHtmlPath = Bundle.main.path(forResource: "about_ru", ofType: "html")!
        }
        else {
            localizedAboutHtmlPath = Bundle.main.path(forResource: "about_en", ofType: "html")!
        }
        
        let htmlHeaderString = "<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header>"
        
        let localizedAboutHtmlData = FileManager.default.contents(atPath: localizedAboutHtmlPath)
        var localizedAboutHtmlString = String(data: localizedAboutHtmlData!, encoding: String.Encoding.utf8)!
        let licensesHtmlPath = Bundle.main.path(forResource: "licenses", ofType: "html")!
        let licensesHtmlData = FileManager.default.contents(atPath: licensesHtmlPath)
        let licensesHtmlString = String(data: licensesHtmlData!, encoding: String.Encoding.utf8)!
        
        localizedAboutHtmlString = localizedAboutHtmlString.replacingOccurrences(of: "[APP_VERSION]", with: MoppApp.versionString)
        localizedAboutHtmlString = localizedAboutHtmlString.replacingOccurrences(of: "[LICENSES]", with: licensesHtmlString)
        
        let baseURL = URL(fileURLWithPath: Bundle.main.bundlePath)
        webView.loadHTMLString(htmlHeaderString + localizedAboutHtmlString, baseURL: baseURL)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if url.scheme == "mailto" || url.scheme == "http" || url.scheme == "https" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return

            }
        }
        decisionHandler(.allow)
    }
}

//
//  AboutViewController.swift
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
import WebKit

class AboutViewController: MoppViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var webView: UIWebView!

    @IBAction func dismissAction() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        titleLabel.text = L(.aboutTitle)
        
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
        
        let localizedAboutHtmlData = FileManager.default.contents(atPath: localizedAboutHtmlPath)
        var localizedAboutHtmlString = String(data: localizedAboutHtmlData!, encoding: String.Encoding.utf8)!
        let licensesHtmlPath = Bundle.main.path(forResource: "licenses", ofType: "html")!
        let licensesHtmlData = FileManager.default.contents(atPath: licensesHtmlPath)
        let licensesHtmlString = String(data: licensesHtmlData!, encoding: String.Encoding.utf8)!
        
        localizedAboutHtmlString = localizedAboutHtmlString.replacingOccurrences(of: "[APP_VERSION]", with: MoppApp.versionString)
        localizedAboutHtmlString = localizedAboutHtmlString.replacingOccurrences(of: "[LICENSES]", with: licensesHtmlString)
        
        let baseURL = URL(fileURLWithPath: Bundle.main.bundlePath)
        webView.loadHTMLString(localizedAboutHtmlString, baseURL: baseURL)
    }
}

extension AboutViewController: UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url else {
            return true
        }
        if url.scheme == "mailto" || url.scheme == "http" || url.scheme == "https" {
            MoppApp.shared.open(url, options: [:], completionHandler: nil)
            return false
        }
        return true
    }
}

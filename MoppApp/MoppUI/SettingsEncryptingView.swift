//
//  SettingsEncryptingView.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2025 Riigi Infosüsteemi Amet
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

import SwiftUI
import UIKit

public let kUseCDoc2Encryption = "kUseCDoc2Encryption"
public let kUseCDoc2OnlineEncryption = "kUseCDoc2OnlineEncryption"
public let kUseCDoc2SelectedService = "kUseCDoc2SelectedService"
public let kUseCDoc2UUID = "kUseCDoc2UUID"
public let kUseCDoc2PostURL = "kUseCDoc2PostURL"
public let kUseCDoc2FetchURL = "kUseCDoc2FetchURL"

extension UICollectionReusableView {
    override open var backgroundColor: UIColor? {
        get { .clear }
        set { }
    }
}

struct LabelTextField: View {
    let title: String
    let placeHolder: String
    @Binding var value: String
    var isEditable: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
            TextField(placeHolder, text: $value)
                .disabled(!isEditable)
                .opacity(isEditable ? 1 : 0.5)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

public struct SettingsEncryptingView: View, Initializable {
    public struct Item : Identifiable {
        public let id: String
        public let name: String
        public let post: String
        public let fetch: String
        public init(id: String, name: String, post: String, fetch: String) {
            self.id = id
            self.name = name
            self.post = post
            self.fetch = fetch
        }
    }

    public class Model: ObservableObject {
         @Published var items: [Item] = [
            Item(id: "00000000-0000-0000-0000-0000000000000000", name: "RIA", post: "https://cdoc2.id.ee:8443", fetch: "https://cdoc2.id.ee:8444"),
            Item(id: "00000000-0000-0000-0000-0000000000000001", name: "Custom", post: "", fetch: "")
         ]
    }

    @Environment(\.dismiss) private var dismiss
    @AppStorage(kUseCDoc2Encryption) private var enableCDoc2Encryption = false
    @AppStorage(kUseCDoc2OnlineEncryption) private var enableCDoc2OnlineEncryption = false
    @AppStorage(kUseCDoc2SelectedService) private var selected = "00000000-0000-0000-0000-0000000000000000"
    @AppStorage(kUseCDoc2UUID) private var uuid = ""
    @AppStorage(kUseCDoc2PostURL) private var post = ""
    @AppStorage(kUseCDoc2FetchURL) private var fetch = ""
    @ObservedObject var model = Model()

    public init() {
        UICollectionView.appearance().backgroundColor = .clear
    }

    public var body: some View {
        Form {
            ZStack {
                Text("Encrypting")
                    .font(.custom("Roboto-Bold", size: 21))
#if !DEBUG
                    .foregroundColor(Color("MoppTitle"))
#endif
                    .padding()

                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Text("✗")
                            .font(.title2)
                            .padding()
                            .foregroundColor(.black)
                    }
                }
            }
            Toggle("Use CDOC2 file format for encryption", isOn: $enableCDoc2Encryption)
            if enableCDoc2Encryption {
                Toggle("Use key transfer server for encryption", isOn: $enableCDoc2OnlineEncryption)

                if enableCDoc2OnlineEncryption {
                    Picker("Name:", selection: $selected) {
                        ForEach(model.items) { item in
                            Text(item.name).tag(item.id)
                        }
                    }
                    .onChange(of: selected) { selectedId in
                        if let selectedItem = model.items.first(where: { $0.id == selectedId }) {
                            uuid = selectedItem.id
                            post = selectedItem.post
                            fetch = selectedItem.fetch
                        }
                    }
                    LabelTextField(title: "UUID", placeHolder: "00000000-0000-0000-0000-0000000000000000", value: $uuid, isEditable: selected == model.items.last?.id)
                    LabelTextField(title: "Fetch URL", placeHolder: "https://cdoc2-fetch.url", value: $fetch, isEditable: selected == model.items.last?.id)
                    LabelTextField(title: "Post URL", placeHolder: "https://cdoc2-post.url", value: $post, isEditable: selected == model.items.last?.id)
                }
            }
        }
#if !DEBUG
        .foregroundColor(Color("MoppText"))
#endif
    }
}

extension SettingsEncryptingView {
    public func withItems(_ items: [Item]) -> SettingsEncryptingView {
        self.model.items = items
        self.model.items.append(SettingsEncryptingView.Item(id: "00000000-0000-0000-0000-0000000000000001", name: "Custom", post: "", fetch: ""))
        return self
    }
}

public class SettingsEncryptingViewController: ViewController<SettingsEncryptingView> {
    public func configure(with items: [SettingsEncryptingView.Item]) {
        _ = rootView?.withItems(items)
    }
}

struct SettingsEncryptingViewPreview: PreviewProvider {
    static var previews: some View {
        SettingsEncryptingView()
            .withItems([
                SettingsEncryptingView.Item(id: "00000000-0000-0000-0000-0000000000000000", name: "RIA", post: "https://cdoc2.id.ee:8443", fetch: "https://cdoc2.id.ee:8444"),
                SettingsEncryptingView.Item(id: "00000000-0000-0000-0000-0000000000000004", name: "RIA2", post: "https://custom-post.url", fetch: "https://custom-fetch.url")
            ])
    }
}

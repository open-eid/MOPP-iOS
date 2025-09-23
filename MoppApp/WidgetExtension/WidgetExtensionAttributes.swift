//
//  WidgetExtensionAttributes.swift
//  MoppApp
//
//  Created by Raul Metsma on 23.09.2025.
//  Copyright © 2025 Riigi Infosüsteemi Amet. All rights reserved.
//

import ActivityKit

struct WidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var code: String
    }
}

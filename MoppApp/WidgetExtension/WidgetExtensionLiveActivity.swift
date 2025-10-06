//
//  WidgetExtensionLiveActivity.swift
//  WidgetExtension
//
//  Created by Raul Metsma on 23.09.2025.
//  Copyright © 2025 Riigi Infosüsteemi Amet. All rights reserved.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WidgetExtensionAttributes.self) { context in
            Text("Smart-ID control code \(context.state.code)")

        } dynamicIsland: { context in
            if #available(iOS 17.0, *) {
                DynamicIsland {
                    DynamicIslandExpandedRegion(.center) {
                        HStack { Text("Smart-ID control code"); Text(context.state.code).bold() }
                    }
                } compactLeading: { Text("Code") }
                  compactTrailing: { Text(context.state.code) }
                  minimal: { Text(context.state.code) }
            } else {
                DynamicIsland {
                    DynamicIslandExpandedRegion(.leading) { Text("Code") }
                    DynamicIslandExpandedRegion(.trailing) { Text(context.state.code).bold() }
                    DynamicIslandExpandedRegion(.bottom) {
                        Text("Smart-ID control code \(context.state.code)")
                    }
                } compactLeading: { Text("Code") }
                  compactTrailing: { Text(context.state.code) }
                  minimal: { Text(context.state.code) }
            }
        }
    }
}

/*
 extension WidgetExtensionAttributes {
    fileprivate static var preview: WidgetExtensionAttributes {
        WidgetExtensionAttributes()
    }
 }

 extension WidgetExtensionAttributes.ContentState {
    fileprivate static var preview: WidgetExtensionAttributes.ContentState {
        WidgetExtensionAttributes.ContentState(code: "1234")
    }
 }

 #Preview("Notification", as: .content, using: WidgetExtensionAttributes.preview) {
    WidgetExtensionLiveActivity()
 } contentStates: {
    WidgetExtensionAttributes.ContentState.preview
 }
 */

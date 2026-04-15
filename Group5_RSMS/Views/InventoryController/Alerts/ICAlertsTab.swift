//
//  ICAlertsTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Alerts tab placeholder.
//

import SwiftUI

struct ICAlertsTab: View {
    var body: some View {
        NavigationStack {
            ComingSoonView(
                title: "Alerts",
                icon: "bell.badge.fill",
                description: "Low-stock warnings, expiry notifications, and reorder point alerts for all products."
            )
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { ICAlertsTab() }

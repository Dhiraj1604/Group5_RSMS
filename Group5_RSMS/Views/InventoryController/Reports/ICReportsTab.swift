//
//  ICReportsTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Reports tab placeholder.
//

import SwiftUI

struct ICReportsTab: View {
    var body: some View {
        NavigationStack {
            ComingSoonView(
                title: "Reports",
                icon: "doc.text.fill",
                description: "Inventory turnover reports, stock valuation, and movement history across all locations."
            )
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { ICReportsTab() }

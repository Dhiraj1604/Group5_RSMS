//
//  ReportsTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Reports tab placeholder.
//

import SwiftUI

struct ReportsTab: View {
    var body: some View {
        NavigationStack {
            ComingSoonView(
                title: "Reports",
                icon: "doc.text.fill",
                description: "View basket trends, category performance, transaction history, and cross-store comparisons."
            )
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { ReportsTab() }

//
//  BMReportsTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Reports tab placeholder.
//

import SwiftUI

struct BMReportsTab: View {
    var body: some View {
        NavigationStack {
            ComingSoonView(
                title: "Reports",
                icon: "doc.text.fill",
                description: "View daily sales reports, performance metrics, and staff activity logs for your boutique."
            )
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { BMReportsTab() }

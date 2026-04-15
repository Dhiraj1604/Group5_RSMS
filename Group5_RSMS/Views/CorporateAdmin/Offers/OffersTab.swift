//
//  OffersTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Offers tab placeholder.
//

import SwiftUI

struct OffersTab: View {
    var body: some View {
        NavigationStack {
            ComingSoonView(
                title: "Offers",
                icon: "gift.fill",
                description: "Create time-bound offers, festival deals, and auto-apply discounts at checkout."
            )
            .navigationTitle("Offers")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { OffersTab() }

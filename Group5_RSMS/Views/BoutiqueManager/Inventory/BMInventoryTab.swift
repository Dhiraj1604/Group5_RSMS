//
//  BMInventoryTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Inventory tab placeholder.
//

import SwiftUI

struct BMInventoryTab: View {
    var body: some View {
        NavigationStack {
            ComingSoonView(
                title: "Inventory",
                icon: "shippingbox.fill",
                description: "View and manage stock levels, request replenishments, and track items in your boutique."
            )
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { BMInventoryTab() }

//
//  ProductsTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Products tab placeholder.
//

import SwiftUI

struct ProductsTab: View {
    var body: some View {
        NavigationStack {
            ComingSoonView(
                title: "Products",
                icon: "tag.fill",
                description: "Set pricing, manage materials, origin, craftsmanship details, and control product listings."
            )
            .navigationTitle("Products")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { ProductsTab() }

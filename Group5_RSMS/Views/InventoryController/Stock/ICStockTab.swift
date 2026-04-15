//
//  ICStockTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Stock management tab placeholder.
//

import SwiftUI

struct ICStockTab: View {
    var body: some View {
        NavigationStack {
            ComingSoonView(
                title: "Stock Management",
                icon: "cube.box.fill",
                description: "Track inventory levels across stores, manage SKUs, and handle stock transfers."
            )
            .navigationTitle("Stock")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { ICStockTab() }

//
//  ICShipmentsTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Shipments tab placeholder.
//

import SwiftUI

struct ICShipmentsTab: View {
    var body: some View {
        NavigationStack {
            ComingSoonView(
                title: "Shipments",
                icon: "shippingbox.fill",
                description: "Track incoming and outgoing shipments, manage purchase orders, and handle receiving."
            )
            .navigationTitle("Shipments")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { ICShipmentsTab() }

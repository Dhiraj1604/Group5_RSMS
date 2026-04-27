//
//  BMSalesTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Sales / POS tab placeholder.
//

import SwiftUI

struct BMSalesTab: View {
    var body: some View {
        NavigationStack {
            ComingSoonView(
                title: "VIP & Events",
                icon: "star.fill",
                description: "Process sales transactions, apply discounts, and manage the point-of-sale system."
            )
            .navigationTitle("VIP & Events")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
        }
    }
}

#Preview { BMSalesTab() }

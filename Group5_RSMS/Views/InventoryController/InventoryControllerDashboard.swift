//
//  InventoryControllerDashboard.swift
//  Group5_RSMS
//
//  Main dashboard for Inventory Controller with 5 tabs.
//

import SwiftUI

struct InventoryControllerDashboard: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ICStockTab()
                .tabItem {
                    Label("Stock", systemImage: "shippingbox.fill")
                }
                .tag(0)

            ICScanTab()
                .tabItem {
                    Label("Scan", systemImage: "barcode.viewfinder")
                }
                .tag(1)

            ICShipmentsTab()
                .tabItem {
                    Label("Shipments", systemImage: "shippingbox.fill")
                }
                .tag(2)

            ICAlertsTab()
                .tabItem {
                    Label("Alerts", systemImage: "bell.badge.fill")
                }
                .tag(3)

            ICReportsTab()
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }
                .tag(4)
        }
        .tint(RSMSTheme.Colors.accentGold)
    }
}

#Preview {
    InventoryControllerDashboard()
        .environment(AppState())
}

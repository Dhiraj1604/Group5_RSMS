//
//  CorporateAdminDashboard.swift
//  Group5_RSMS
//
//  Main dashboard for Corporate Admin with 5 tabs.
//

import SwiftUI

struct CorporateAdminDashboard: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardTab()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }
                .tag(0)

            StoresTab()
                .tabItem {
                    Image(systemName: "building.2.fill")
                    Text("Stores")
                }
                .tag(1)

            ProductsTab()
                .tabItem {
                    Image(systemName: "tag.fill")
                    Text("Products")
                }
                .tag(2)

            OffersTab()
                .tabItem {
                    Image(systemName: "gift.fill")
                    Text("Offers")
                }
                .tag(3)

            ReportsTab()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Reports")
                }
                .tag(4)
        }
        .tint(RSMSTheme.Colors.accentGold)
        .task {
            async let storesLoad: () = appState.loadStores()
            async let productsLoad: () = appState.fetchProducts()
            async let inventoryLoad: () = appState.fetchTotalInventoryCount()
            _ = await (storesLoad, productsLoad, inventoryLoad)
        }
    }
}

#Preview {
    CorporateAdminDashboard()
        .environment(AppState())
}

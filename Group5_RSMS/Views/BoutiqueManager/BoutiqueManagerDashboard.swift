//
//  BoutiqueManagerDashboard.swift
//  Group5_RSMS
//
//  Main dashboard for Boutique Manager with 5 tabs.
//

import SwiftUI

struct BoutiqueManagerDashboard: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
//            BMDashboardTab()
//                .tabItem {
//                    Image(systemName: "chart.bar.fill")
//                    Text("Dashboard")
//                }
//                .tag(0)

            BMInventoryTab()
                .tabItem {
                    Image(systemName: "shippingbox.fill")
                    Text("Inventory")
                }
                .tag(1)

//            BMSalesTab()
//                .tabItem {
//                    Image(systemName: "cart.fill")
//                    Text("Sales")
//                }
//                .tag(2)

//            BMStaffTab(boutiqueId: appState.currentStoreID ?? UUID())
//                .tabItem {
//                    Image(systemName: "person.3.fill")
//                    Text("Staff")
//                }
//                .tag(3)
//
//            BMReportsTab()
//                .tabItem {
//                    Image(systemName: "doc.text.fill")
//                    Text("Reports")
//                }
//                .tag(4)
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
    BoutiqueManagerDashboard()
        .environment(AppState())
}

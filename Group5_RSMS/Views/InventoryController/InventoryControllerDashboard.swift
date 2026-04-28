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
                    Image(systemName: "archivebox.fill")
                    Text("Stock")
                }
                .tag(0)

            ICScanTab()
                .tabItem {
                    Image(systemName: "barcode.viewfinder")
                    Text("Scan")
                }
                .tag(1)

            ICShipmentsTab()
                .tabItem {
                    Image(systemName: "shippingbox.fill")
                    Text("Shipments")
                }
                .tag(2)

            StockCheckView()
                .tabItem {
                    Image(systemName: "checklist.checked")
                    Text("Audit")
                }
                .tag(3)

            ICReportsTab()
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
    InventoryControllerDashboard()
        .environment(AppState())
}
